function [outputArg1,outputArg2] = calibFast(hw, verbose)

initSlowDelay = bitand(hw.readAddr('a0060008'), hex2dec('7FFFFFFF'));
initFastDelay = double(hw.readAddr('a0050548') + hw.readAddr('a0050458'));

nMaxIterations = 1;

fastDelay = initFastDelay;
slowDelay = initSlowDelay;

hw.cmd('iwb e2 06 01 00'); % set the lowest laser gain to 0

for i=1:nMaxIterations
    
    hw.setReg('DESTaltIrEn', false);
    hw.shadowUpdate();
    Calibration.aux.hwSetScanDir(hw, 2);
    
    ir = hw.getFrame(30).i;

    hw.setReg('DESTaltIrEn', true);
    hw.shadowUpdate();
    pause(0.2);
    
    alt = hw.getFrame(30).i;

    Calibration.aux.hwSetScanDir(hw, 0);
    alt0 = hw.getFrame(30).i;

    Calibration.aux.hwSetScanDir(hw, 1);
    alt1 = hw.getFrame(30).i;

    pxDiff = Calibration.aux.findCoarseDelay(ir, alt0, alt1);

    if(verbose)
        figure(11711);
        subplot(2,2,1); imagesc(ir);
        subplot(2,2,3); imagesc(alt);
        subplot(2,2,2); imagesc(alt0);
        subplot(2,2,4); imagesc(alt1);
        tStr = sprintf('Fast delay diff : %g', pxDiff);
        title(tStr);
        drawnow;
    end
    
    if (pxDiff < 0.2)
        break;
    end
    
    % time per pixel in spherical coordinates
    nomMirroFreq = 20e3;
    %delayDiff = acos(-(pxDiff/size(ir,1)*2-1))/(2*pi*nomMirroFreq)/2*1e9;
    delayDiff = 25*10^3*pxDiff/size(ir,1)/2;
    
    slowDelay = slowDelay + delayDiff;
    fastDelay = fastDelay + delayDiff;
    
    Calibration.aux.hwSetDelay(hw, slowDelay, false);
    Calibration.aux.hwSetDelay(hw, fastDelay, true);

end

hw.setReg('DESTaltIrEn', false);
hw.shadowUpdate();
Calibration.aux.hwSetScanDir(hw, 2);


end

