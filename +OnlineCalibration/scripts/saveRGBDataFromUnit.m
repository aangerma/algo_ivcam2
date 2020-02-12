%% During streaming in IPDEV - run this script and it will save a mat file with the needed parameters of the depth and RGB frames

savePath = 'X:\Data\IvCam2\OnlineCalibration\F9440842\camerasParams.mat';

res = [480,640];
RGBRes = [1920 ,1080];

hw = HWinterface;
[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
startIxRgb = 6;
Krgb([1,5,7,8,4]) = intr([startIxRgb:startIxRgb+3,1]);%intr([6:9,1]);
drgb = intr(startIxRgb+4:startIxRgb+8);
[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';
camerasParams.rgbRes = RGBRes;
camerasParams.rgbPmat = Krgb*[Rrgb Trgb];
camerasParams.rgbDistort = drgb;
camerasParams.Krgb = Krgb;
camerasParams.depthRes = res;
camerasParams.zMaxSubMM = hw.z2mm;
camerasParams.Kdepth = hw.getIntrinsics;
camerasParams.Trgb = Trgb;
camerasParams.Rrgb = Rrgb;

save(savePath, 'camerasParams');