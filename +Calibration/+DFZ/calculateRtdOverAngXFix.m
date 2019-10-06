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
    delayVec = regs.DEST.txFRQpd(1)*ones(1,calibParams.rtdOverAngX.res,'single');
    setRtdOverAngXFix(hw,delayVec);
    pause(2);
    inputPath = fullfile(ivcam2tempdir,'rtdOverAngX'); 
    pathConstant = fullfile(inputPath,'frames_constant');
    Calibration.aux.SaveFramesWrapper(hw , 'Z' , calibParams.rtdOverAngX.nFrames, pathConstant);     

    delayVec = regs.DEST.txFRQpd(1)-single(1:calibParams.rtdOverAngX.res)*calibParams.rtdOverAngX.stepSize;
    setRtdOverAngXFix(hw,delayVec);
    pause(2);
    inputPath = fullfile(ivcam2tempdir,'rtdOverAngX'); 
    pathSteps = fullfile(inputPath,'frames_steps');
    Calibration.aux.SaveFramesWrapper(hw , 'Z' , calibParams.rtdOverAngX.nFrames, pathSteps);     

    tablefn = RtdOverAngX_Calib_Calc(inputPath,calibParams,regs,luts);
    
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
