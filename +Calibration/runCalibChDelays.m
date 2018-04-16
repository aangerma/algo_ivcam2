function [regs,errSlow,errFast] = runCalibChDelays(hw, params)

verbose = params.verbose;

if (params.debug)
    debugFolder = fullfile(params.internalFolder, filesep, 'dbgDelays');
    mkdirSafe(debugFolder);
else
    debugFolder = [];
end

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

fw = hw.getFirmware();
regs = fw.get();

initFastDelay = double(hw.readAddr('a0050548')); %double(regs.EXTL.conLocDelayFastC);
initSlowDelay = 64;
Calibration.aux.hwSetDelay(hw, initSlowDelay, false);

qScanLength = 1024;
delayFast = initFastDelay;

hw.setReg('DESTaltIrEn'    ,false);
hw.setReg('DIGGsphericalEn',true);
hw.setReg('JFILsort1bypassMode',uint8(0));
hw.setReg('JFILsort2bypassMode',uint8(0));
hw.shadowUpdate();

step=ceil(2*qScanLength/16);
delayFast = findBestDelay(hw, delayFast, step, 4, 'fastCoarse', verbose, debugFolder);

% alternate IR : correlation peak from DEST 
hw.setReg('DESTaltIrEn'    ,true);
hw.shadowUpdate();

step = 16;
try
    [delayFast, errFast] = findBestDelay(hw, delayFast, step, 2, 'fastFine', verbose, debugFolder);
catch
    warning('fastFine failed');
end

if (errFast >= 1000)
    return;
end

hw.setReg('JFILsort1bypassMode',uint8(1));
hw.setReg('JFILsort2bypassMode',uint8(1));
hw.setReg('DESTaltIrEn'    ,false);
hw.setReg('DIGGsphericalEn',false);
hw.shadowUpdate();

delaySlow = initSlowDelay;
step = 32;

%delaySlow = findBestDelay(hw, delaySlow, step, 6, 'slowCoarse', verbose, debugFolder);

hw.setReg('JFILsort1bypassMode',uint8(0));
hw.setReg('JFILsort2bypassMode',uint8(0));
hw.shadowUpdate();

step = 16;
try
    [delaySlow, errSlow] = findBestDelay(hw, delaySlow, step, 2, 'slowFine', verbose, debugFolder);
catch
    warning('slowFine failed');
    errSlow = 1000; % in pixels
end

regs.EXTL.conLocDelaySlow = uint32(delaySlow)+uint32(bitshift(1,31));
mod8=mod(delayFast,8);
regs.EXTL.conLocDelayFastC= uint32(delayFast-mod8);
regs.EXTL.conLocDelayFastF=uint32(mod8);


end

function [delay, err] = findBestDelay(hw, initDelay, initStep, minStep, iterType, verbose, debugFolder)

coarse = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'slowCoarse'));
fast = or(strcmp(iterType, 'fastCoarse'), strcmp(iterType, 'fastFine'));

R = 3;
range = -1:1;

images = cell(1, 3);
errors = nan(1,R);

delay = initDelay;
step = initStep;

hwCurrDelay = 0;

for ic=1:10
    if (step <= minStep)
        break;
    end
    
    delays = max(0, round(delay+range'*step));

    for i=1:R
        if ~isnan(errors(i))
            continue;
        end
        
        hwCurrDelay = delays(i);
        Calibration.aux.hwSetDelay(hw, delays(i), fast);

        if (coarse)
            [errors(i), ir1, ir2] = findTwoDirError(hw);
            errors(i) = abs(errors(i));
            images{i} = double(ir1)-double(ir2);

            if (~isempty(debugFolder))
                irFilename = sprintf('irFrame_%s_i%02d-%d_%05d_dir1.bini', iterType, ic, i, delays(i));
                irFullpath = fullfile(debugFolder, filesep, irFilename);
                io.writeBin(irFullpath, ir1);
                irFilename = sprintf('irFrame_%s_i%02d-%d_%05d_dir2.bini', iterType, ic, i, delays(i));
                irFullpath = fullfile(debugFolder, filesep, irFilename);
                io.writeBin(irFullpath, ir2);
            end
        else
            frame = hw.getFrame();
            images{i} = double(frame.i);
            errors(i) = Calibration.aux.calcDelayFineError(images{i});
            if (~isempty(debugFolder))
                irFilename = sprintf('irFrame_%s_i%02d-%d_%05d.bini', iterType, ic, i, delays(i));
                irFullpath = fullfile(debugFolder, filesep, irFilename);
                io.writeBin(irFullpath, images{i});
            end
        end
    end
    
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

    minInd = minind(errors);
    bestDelay = delays(minInd);
    delay = bestDelay;
    err = errors(minInd);
    
    switch minInd
        case 1
            images{3} = images{2};
            images{2} = images{1};
            errors(2:3) = errors(1:2);
            errors(1) = nan;
        case 2
            errors(1) = nan;
            errors(3) = nan;
            step = floor(step/2);
        case 3
            images{1} = images{2};
            images{2} = images{3};
            errors(1:2) = errors(2:3);
            errors(3) = nan;
    end

end

if (hwCurrDelay ~= delay)
    Calibration.aux.hwSetDelay(hw, delay, fast);
end

end

function [err, ir1, ir2] = findTwoDirError(hw)

scanDir1gainAddr = '85080000';
scanDir2gainAddr = '85080480';
gainCalibValue  = '000ffff0';
saveVal(1) = hw.readAddr(scanDir1gainAddr);
saveVal(2) = hw.readAddr(scanDir2gainAddr);
hw.writeAddr(scanDir1gainAddr,gainCalibValue,true);
pause(0.15);

frame1 = hw.getFrame();
ir1 = frame1.i;
z1 = frame1.z;

hw.writeAddr(scanDir1gainAddr,saveVal(1),true);
hw.writeAddr(scanDir2gainAddr,gainCalibValue,true);
pause(0.15);

frame2 = hw.getFrame();
ir2 = frame2.i;
z2 = frame2.z;

hw.writeAddr(scanDir2gainAddr,saveVal(2),true);
pause(0.1);

res1 = Validation.edgeTrans(double(ir1), 9, [9 13]);
res2 = Validation.edgeTrans(double(ir2), 9, [9 13]);

err = mean((res1.points(:,2)-res2.points(:,2)));

end


