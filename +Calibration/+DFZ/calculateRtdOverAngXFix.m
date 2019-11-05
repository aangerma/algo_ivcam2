function [  ] = calculateRtdOverAngXFix( hw,runParams,calibParams,regs,luts, fprintff) 
if (runParams.DFZ)
    hw.stopStream;
    hw.cmd('rst');
    pause(10);
    clear hw;
    pause(1);
    hw = HWinterface;
    hw.cmd('DIRTYBITBYPASS');
    fprintff('Calibrating rtd over angX table...\n');
    res = runParams.calibRes;
    isXGA = all(res==[768,1024]);
    if isXGA
        hw.cmd('ENABLE_XGA_UPSCALE 1')
    end
    hw.startStream(0,runParams.calibRes);
    [r] = rtdOverAngXFixInit(hw,runParams,fprintff);
    
    Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'Rtd Over AngX - Board should cover the entire fov',1);
    [delayVecNoChange,delayVecSteps] = RtdOverAngXStateValues_Calib_Calc(calibParams,regs);
    
    setRtdOverAngXFix(hw,delayVecNoChange);
    pause(2);
    depthDataConstant = Calibration.aux.captureFramesWrapper(hw, 'Z', calibParams.rtdOverAngX.nFrames);

    setRtdOverAngXFix(hw,delayVecSteps);
    pause(2);
    depthDataSteps = Calibration.aux.captureFramesWrapper(hw, 'Z', calibParams.rtdOverAngX.nFrames);

    tablefn = RtdOverAngX_Calib_Calc(depthDataConstant, depthDataSteps, calibParams, regs, luts);
    
    r.reset();
    
    fprintff('Burning RtdOverAngX table...\n');
    try
        hw.cmd(sprintf('WrCalibInfo %s',tablefn));
        fprintff('Done\n');
    catch
        fprintff('failed to burn Rtd Over AngX table\n');
    end
end
end
function setRtdOverAngXFix(hw,delayVec)
cmdstr = ['CONFIG_SYSDELAY_DATA ',dec2hex(numel(delayVec)),' ',strjoin(single2hex(delayVec),' ')];
hw.cmd(cmdstr);
end
function r = rtdOverAngXFixInit(hw,runParams,fprintff)

r = Calibration.RegState(hw);
r.add('JFILinvBypass',true);
r.add('DESTdepthAsRange',true);
r.set();

end
