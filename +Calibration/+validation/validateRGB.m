function [rgbRes,frames] = validateRGB( hw, calibParams,runParams, fprintff)
% set LR preset
hw.setPresetControlState(1);
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
hw.shadowUpdate;

pause(5);
depthFrame = hw.getFrame(calibParams.numOfFrames);
rgbFrame  = hw.getColorFrame(calibParams.numOfFrames); %Going to 1920 1080?


[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
% 
% Krgb([1,5,7,8,4]) = intr([6:9,1]);
Krgb([1,5,7,8,4]) = intr([calibParams.startIxRgb:calibParams.startIxRgb+3,1]);%intr([17:20,1]); %why again?
[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';

P = Krgb*[Rrgb Trgb];
end

