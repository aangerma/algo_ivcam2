function [rgbRes,frames] = validateRGB( hw, calibParams,runParams, fprintff)
% set LR preset
hw.setPresetControlState(1);
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
hw.shadowUpdate;

pause(5);
depthframe = hw.getFrame(calibParams.numOfFrames);

end

