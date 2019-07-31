function [rgbPassed,rgbTable,results,im,rgbs] = cal_rgb(imagePath,calibParams,IrImSize,Kdepth,z2mm,fprintff,runParams)
    results = struct;
    rgbTable = [];
    rgbPassed = 0;
    
    poses = dirFolders(imagePath);
    
    IrImSize = flip(IrImSize);
    for i=1:length(poses)
        filesIR = dirFiles(fullfile(imagePath,poses{i}),'I*',1);
        filesRGB = dirFiles(fullfile(imagePath,poses{i}),'RGB*',1);
        img = readAllBytes(filesIR{1});
        im(i).i = rot90(reshape(img,flip(IrImSize)),2);
        img = typecast(readAllBytes(filesRGB{1}),'uint16');
        rgbs{i} = reshape(double(bitand(img,255)),calibParams.rgb.imSize)';
    end
    
    fn = fullfile(runParams.outputFolder, 'mat_files' , 'RGB_frames.mat');
    save(fn,'im' , 'rgbs' ,'calibParams' );
    
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

