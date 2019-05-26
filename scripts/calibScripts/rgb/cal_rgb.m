function [rgbPassed,rgbTable,results] = cal_rgb(imagePath,calibPrams,Kdepth,z2mm)

    filesIR = dirFiles(imagePath,'I*',1);
    filesRGB = dirFiles(imagePath,'RGB*',1);
    rgbImSize = calibPrams.rgb.imSize;
    IrImSize = flip(calibPrams.gnrl.externalImSize);
    for i=1:length(filesIR)
        img = readAllBytes(filesIR{i});
        im(i).i = reshape(img,flip(IrImSize))';
        img = typecast(readAllBytes(filesRGB{i}),'uint16');
        rgbs{i} = reshape(double(bitand(img,255)),rgbImSize);
    end
    
    [cbCorners,cornersValid,params] = Calibration.rgb.prepareData(im,rgbs,calibParams);
    
    if sum(cornersValid) < 3
        fprintff('[x] not enough valid views, skipping\n');
        return
    end
    res = Calibration.rgb.computeCal(cbCorners(cornersValid,:),Kdepth,params);
    rgbTable = Calibration.rgb.buildRGBTable(res,params);
    results.rgbIntReprojRms = res.color.rms;
    results.rgbExtReprojRms = res.extrinsics.rms;
    rgbPassed = true;
end

