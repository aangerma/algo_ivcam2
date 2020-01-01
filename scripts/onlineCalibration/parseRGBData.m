function unitData = parseRGBData(unitData)
calibParams.gnrl.rgb.startIxRgb = 6;
intr = typecast(unitData.rgbCalibData,'single');
Krgb = eye(3);
Krgb([1,5,7,8,4]) = intr([calibParams.gnrl.rgb.startIxRgb:calibParams.gnrl.rgb.startIxRgb+3,1]);%intr([6:9,1]);
drgb = intr(calibParams.gnrl.rgb.startIxRgb+4:calibParams.gnrl.rgb.startIxRgb+8);
[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';
camerasParams.rgbRes = calibParams.gnrl.rgb.res;
camerasParams.rgbPmat = Krgb*[Rrgb Trgb];
camerasParams.rgbDistort = drgb;
camerasParams.Krgb = Krgb;
camerasParams.depthRes = runParams.calibRes;
camerasParams.zMaxSubMM = hw.z2mm;
camerasParams.Kdepth = hw.getIntrinsics;
    
end

