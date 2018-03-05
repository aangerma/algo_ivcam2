function [regs,errSlow,errFast] = runCalibChDelays(hw, verbose, debugOut)

if ~exist('verbose','var')
  verbose = false;  
end

if ~exist('debugOut','var')
  debugOut = false;  
end

regs = [];
errFast = 1000; % in pixels
errSlow = 1000; % in pixels


hw.setReg('RASTbiltBypass'     ,true);
hw.setReg('JFILbypass'         ,false);
hw.setReg('JFILbilt1bypass'    ,true);
hw.setReg('JFILbilt2bypass'    ,true);
hw.setReg('JFILbilt3bypass'    ,true);
hw.setReg('JFILbiltIRbypass'   ,true);
hw.setReg('JFILdnnBypass'      ,true);
hw.setReg('JFILedge1bypassMode',uint8(1));
hw.setReg('JFILedge4bypassMode',uint8(1));
hw.setReg('JFILedge3bypassMode',uint8(1));
hw.setReg('JFILgeomBypass'     ,true);
hw.setReg('JFILgrad1bypass'    ,true);
hw.setReg('JFILgrad2bypass'    ,true);
hw.setReg('JFILirShadingBypass',true);
hw.setReg('JFILinnBypass'      ,true);
hw.setReg('JFILsort1bypassMode',uint8(1));
hw.setReg('JFILsort2bypassMode',uint8(1));
hw.setReg('JFILsort3bypassMode',uint8(1));
hw.setReg('JFILupscalexyBypass',true);
hw.setReg('JFILgammaBypass'    ,false);
hw.shadowUpdate();

initFastDelay = hex2dec('0000719A');
initSlowDelay = 32;


qScanLength = 1024;
step=ceil(2*qScanLength/5);
delayFast = initFastDelay;

% alternate IR : correlation peak from DEST 
hw.setReg('DESTaltIrEn'    ,true);
hw.shadowUpdate();

delayFast = findBestDelay(hw, delayFast, step, 6, 'fastCoarse', verbose, debugOut);

hw.setReg('JFILsort1bypassMode',uint8(0));
hw.setReg('JFILsort2bypassMode',uint8(0));
hw.shadowUpdate();

step = 16;
try
    [delayFast, errFast] = findBestDelay(hw, delayFast, step, 2, 'fastFine', verbose, debugOut);
catch
    warning('fastFine failed');
end

if (errFast >= 1000)
    return;
end

hw.setReg('JFILsort1bypassMode',uint8(1));
hw.setReg('JFILsort2bypassMode',uint8(1));
hw.setReg('DESTaltIrEn'    ,false);
hw.shadowUpdate();

delaySlow = initSlowDelay;
step = 32;

delaySlow = findBestDelay(hw, delaySlow, step, 6, 'slowCoarse', verbose, debugOut);

hw.setReg('JFILsort1bypassMode',uint8(0));
hw.setReg('JFILsort2bypassMode',uint8(0));
hw.shadowUpdate();

step = 16;
try
    [delaySlow, errSlow] = findBestDelay(hw, delaySlow, step, 2, 'slowFine', verbose, debugOut);
catch
    warning('slowFine failed');
    errSlow = 1000; % in pixels
end

regs.EXTL.conLocDelaySlow = uint32(delaySlow);
regs.EXTL.conLocDelayFastC= uint32(delayFast/8)*8;
regs.EXTL.conLocDelayFastF=uint32(mod(delayFast,8));




end

function [delay, err] = findBestDelay(hw, initDelay, initStep, minStep, iterType, verbose, debugOut)

coarse = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'slowCoarse'));
fast = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'fastFine'));

R = 3;
range = -1:1;

images = cell(1, 3);
errors = zeros(1,R);

delay = initDelay;
step = initStep;

hwCurrDelay = 0;

for ic=1:10
    if (step <= minStep)
        break;
    end
    
    delays = max(0, round(delay+range'*step));

    for i=1:R
        if ~isempty(images{i})
            continue;
        end
        
        hwCurrDelay = delays(i);
        hwSetDelay(hw, delays(i), fast);
        
        frame = hw.getFrame();
        images{i} = double(frame.i);
        
        if (debugOut)
            irFilename = sprintf('irFrame_%s_i%02d-%d_%05d.bini', iterType, ic, i, delays(i));
            io.writeBin(irFilename, frame.i);
        end
        
        if (coarse)
            errors(i) = Calibration.aux.calcDelayCoarseError(images{i});
        else
            errors(i) = Calibration.aux.calcDelayFineError(images{i});
        end
    end
    
    minInd = minind(errors);
    bestDelay = delays(minInd);
    delay = bestDelay;
    err = errors(minInd);
    
    if (verbose)
        figure(11711); 
        ax=nan(1,R);
        for i=1:R
            ax(i)=subplot(2,R,i);
            imagesc(images{i},prctile_(images{i}(images{i}~=0),[10 90])+[0 1e-3]);
        end
        linkaxes(ax);
        subplot(2,3,4:6); plot(delays,errors,'o-');
        title (sprintf('%s - step: %d', iterType, int32(step)));
        drawnow;
    end
    
    switch minInd
        case 1
            images{3} = images{2};
            images{2} = images{1};
            images{1} = [];
            errors(2:3) = errors(1:2);
        case 2
            images{1} = [];
            images{3} = [];
            step = floor(step/2);
        case 3
            images{1} = images{2};
            images{2} = images{3};
            images{3} = [];
            errors(1:2) = errors(2:3);
    end

end

if (hwCurrDelay ~= delay)
    hwSetDelay(hw, delay, fast);
end

end

function hwSetDelay(hw, delay, fast)

%{
//---------FAST-------------
mwd a0050548 a005054c 00007110 //[m_regmodel.proj_proj.RegsProjConLocDelay]                      (moves loc+metadata to Hfsync 8inc)
mwd a0050458 a005045c 00000004 //[m_regmodel.proj_proj.RegsProjConLocDelayHfclkRes] TYPE_REG     (moves loc+metadata to Hfsync [0-7])
//--------SLOW-------------
mwd a0060008 a006000c 80000020  //[m_regmodel.ansync_ansync_rt.RegsAnsyncAsLateLatencyFixEn] TYPE_REG
%}

fastDelayCmdMul8 = 'mwd a0050548 a005054c %08x // RegsProjConLocDelay';
fastDelayCmdSub8 = 'mwd a0050458 a005045c %08x // RegsProjConLocDelayHfclkRes';
slowDelayCmd = 'mwd a0060008 a006000c 8%07x // RegsAnsyncAsLateLatencyFixEn';

hw.stopStream();
%pause(0.05);

if (fast)
    mod8 = mod(delay, 8);
    hw.runCommand(sprintf(fastDelayCmdMul8, delay - mod8));
    hw.runCommand(sprintf(fastDelayCmdSub8, mod8));
else
    hw.runCommand(sprintf(slowDelayCmd, delay));
end

hw.shadowUpdate();

hw.restartStream();
pause(0.2);

end


% function delay = run5SampleIterations(hw, baseDelay, step, iterType, verbose)
% 
% coarse = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'slowCoarse'));
% fast = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'fastFine'));
% 
% %{
% //---------FAST-------------
% mwd a0050548 a005054c 00007110 //[m_regmodel.proj_proj.RegsProjConLocDelay]                      (moves loc+metadata to Hfsync 8inc)
% mwd a0050458 a005045c 00000004 //[m_regmodel.proj_proj.RegsProjConLocDelayHfclkRes] TYPE_REG     (moves loc+metadata to Hfsync [0-7])
% //--------SLOW-------------
% mwd a0060008 a006000c 80000020  //[m_regmodel.ansync_ansync_rt.RegsAnsyncAsLateLatencyFixEn] TYPE_REG
% %}
% 
% fastDelayCmdMul8 = 'mwd a0050548 a005054c %08x // RegsProjConLocDelay';
% fastDelayCmdSub8 = 'mwd a0050458 a005045c %08x // RegsProjConLocDelayHfclkRes';
% slowDelayCmd = 'mwd a0060008 a006000c 8%07x // RegsAnsyncAsLateLatencyFixEn';
% 
% nSampleIterations = 5;
% R = nSampleIterations;
% range = round(-(R-1)/2:(R-1)/2);
% 
% delays = max(0, round(baseDelay+range'*step));
% 
% if (all(diff(delays)==0))
%     delay = baseDelay;
%     return;
% end
% 
% irImages = cell(1,R);
% errors = zeros(1,R);
% 
% for i=1:nSampleIterations
%     
%     hw.stopStream();
%     pause(0.1);
%     
%     if (fast)
%         mod8 = mod(delays(i),8);
%         hw.runCommand(sprintf(fastDelayCmdMul8, delays(i) - mod8));
%         hw.runCommand(sprintf(fastDelayCmdSub8, mod8));
%     else
%         hw.runCommand(sprintf(slowDelayCmd, delays(i)));
%     end
%     
%     hw.shadowUpdate();
%     
%     hw.restartStream();
%     pause(0.2);
%     
%     frame = hw.getFrame();
%     irImages{i} = double(frame.i);
% end
% 
% for i=1:nSampleIterations
%     if (coarse)
%         errors(i) = Calibration.aux.calcDelayCoarseError(irImages{i});
%     else
%         errors(i) = Calibration.aux.calcDelayFineError(irImages{i});
%     end
% end
% 
% minInd = minind(errors);
% bestDelay = delays(minInd);
% err = errors(minInd);
% 
% if (verbose)
%     figure(11711);
%     for i=1:R
%         ax(i)=subplot(2,R,i);
%         imagesc(irImages{i},prctile_(irImages{i}(irImages{i}~=0),[10 90])+[0 1e-3]);
%     end
%     linkaxes(ax);
%     subplot(2,3,4:6); plot(delays,errors,'o-');
%     title iterType;
%     drawnow;
% end
% 
% delay = bestDelay;
% 
% end
