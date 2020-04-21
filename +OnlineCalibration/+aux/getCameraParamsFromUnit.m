function [camerasParams] = getCameraParamsFromUnit(hw,rgbRes)

[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
switch rgbRes(2)
    case 1080
        startIxRgb = 6;
    case 720
        startIxRgb = 17;
    case 540
        startIxRgb = 28;
    case 480
        startIxRgb = 39;
    case 360
        startIxRgb = 50;
    otherwise
            error('This resolution is not supported!')
end
Krgb([1,5,7,8,4]) = intr([startIxRgb:startIxRgb+3,1]);%intr([6:9,1]);
drgb = intr(startIxRgb+4:startIxRgb+8);
[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';
camerasParams.rgbPmat = Krgb*[Rrgb Trgb];
camerasParams.rgbDistort = drgb;
camerasParams.Krgb = Krgb;
camerasParams.zMaxSubMM = hw.z2mm;
camerasParams.Kdepth = hw.getIntrinsics;
camerasParams.Trgb = Trgb;
camerasParams.Rrgb = Rrgb;
end

