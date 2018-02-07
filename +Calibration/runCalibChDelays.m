function [delayFast, delaySlow] = runCalibChDelays(hw, verbose)

fNameNoFiltersScript = fullfile(fileparts(mfilename('fullpath')),'IVCAM20Scripts','irDelayNoFilters.txt');
hw.runScript(fNameNoFiltersScript);


initFastDelay = hex2dec('0000719A');
initSlowDelay = 32;


qScanLength = 1024;
step=ceil(2*qScanLength/5);
delayFast = initFastDelay;

% alternate IR : correlation peak from DEST 

hw.runCommand('mwd a00e084c a00e0850 00000001 //DESTaltIrEn');
hw.shadowUpdate();

for ic=1:10
    prevDelay = delayFast;
    delayFast = runSampleIterations(hw, delayFast, step, 'fastCoarse', verbose);
    step = floor(step/2);
    if (abs(prevDelay - delayFast) < 3)
        break;
    end
end

hw.runCommand('mwd a00e1b24 a00e1b28 00000000 //JFILsort1bypassMode');
hw.runCommand('mwd a00e1b40 a00e1b44 00000000 //JFILsort2bypassMode');
hw.shadowUpdate();

step = 12;
for ic=1:10
    prevDelay = delayFast;
    delayFast = runSampleIterations(hw, delayFast, step, 'fastFine', verbose);
    step = floor(step/2);
    if (abs(prevDelay - delayFast) < 1)
        break;
    end
end

hw.runCommand('mwd a00e1b24 a00e1b28 00000001 //JFILsort1bypassMode');
hw.runCommand('mwd a00e084c a00e0850 00000000 //DESTaltIrEn');
hw.shadowUpdate();

delaySlow = initSlowDelay;
step = 32;

for ic=1:10
    prevDelay = delaySlow;
    delaySlow = runSampleIterations(hw, delaySlow, step, 'slowCoarse', verbose);
    step = floor(step/2);
    if (abs(prevDelay - delaySlow) < 3)
        break;
    end
end

hw.runCommand('mwd a00e1b24 a00e1b28 00000000 //JFILsort1bypassMode');
hw.shadowUpdate();

step = 16;
for ic=1:10
    prevDelay = delaySlow;
    delaySlow = runSampleIterations(hw, delaySlow, step, 'slowFine', verbose);
    step = floor(step/2);
    if (abs(prevDelay - delaySlow) < 2)
        break;
    end
end

end

function delay = runSampleIterations(hw, baseDelay, step, iterType, verbose)

coarse = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'slowCoarse'));
fast = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'fastFine'));

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

nSampleIterations = 5;
R = nSampleIterations;
range = round(-(R-1)/2:(R-1)/2);

delays = max(0, round(baseDelay+range'*step));

if (all(diff(delays)==0))
    delay = baseDelay;
    return;
end

irImages = cell(1,R);
errors = zeros(1,R);

for i=1:nSampleIterations
    
    hw.stopStream();
    pause(0.1);
    
    if (fast)
        mod8 = mod(delays(i),8);
        hw.runCommand(sprintf(fastDelayCmdMul8, delays(i) - mod8));
        hw.runCommand(sprintf(fastDelayCmdSub8, mod8));
    else
        hw.runCommand(sprintf(slowDelayCmd, delays(i)));
    end
    
    hw.shadowUpdate();
    
    hw.restartStream();
    pause(0.2);
    
    frame = hw.getFrame();
    irImages{i} = double(frame.i);
end

for i=1:nSampleIterations
    if (coarse)
        errors(i) = Calibration.aux.calcDelayCoarseError(irImages{i});
    else
        errors(i) = Calibration.aux.calcDelayFineError(irImages{i});
    end
end

minInd = minind(errors);
baseDelay = delays(minInd);
err = errors(minInd);

if (verbose)
    figure(11711);
    for i=1:R
        aa(i)=subplot(2,R,i);
        imagesc(irImages{i},prctile_(irImages{i}(irImages{i}~=0),[10 90])+[0 1e-3]);
    end
    subplot(2,3,4:6)
    plot(delays,errors,'o-'); %set(gca,'xlim',[delays(1)-step/2 delays(end)+step/2]);
    line([baseDelay baseDelay ], minmax(err),'color','r');
    linkaxes(aa);
    drawnow;
end

delay = baseDelay;

end
