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
        z = Calibration.aux.GetFramesFromDir(fullfile(imagePath,poses{i}),IrImSize(1), IrImSize(2),'Z');
        im(i).z = rot90(z(:,:,1),2);
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
    %%
    params.camera = struct('zMaxSubMM',z2mm,'K',Kdepth);
    params.rgbPmat = res.color.k*[res.extrinsics.r res.extrinsics.t];
    params.rgbDistort = res.color.d;
    params.Krgb = res.color.k;
    params.Krgbn = res.color.Kn;
    [resultsUvLf,~] = calcUVandLF( im, params, rgbs);
    results = Validation.aux.mergeResultStruct(results,resultsUvLf);
    %%
    rgbPassed = true;
end


function [results,dbg] = calcUVandLF( depthFrames, params, rgbFrames)
uvMapRmse = nan(1,length(rgbFrames));
uvMapMaxErr95 = nan(1,length(rgbFrames));
uvMapMaxErr = nan(1,length(rgbFrames));
lineFitRmsErrHor2dRGB = nan(1,length(rgbFrames));
lineFitRmsErrVer2dRGB = nan(1,length(rgbFrames));
lineFitMaxErrHor2dRGB = nan(1,length(rgbFrames));
lineFitMaxErrVer2dRGB = nan(1,length(rgbFrames));
for  k =1:length(rgbFrames)
    
    frame.i = depthFrames(k).i;
    frame.z = depthFrames(k).z;
    frame.rgb = rgbFrames(k);
    [~, resultsUvMap,dbg] = Validation.metrics.geomReprojectErrorUV(frame, params);
    uvMapRmse(1,k) = resultsUvMap.reproErrorUVPixRmsMeanAF;
    uvMapMaxErr(1,k) = resultsUvMap.reproErrorUVPixRmsMaxAF;
    uvMapMaxErr95(1,k) = resultsUvMap.maxErr95AF;

    pts = cat(3,dbg.DAF .cornersRGB(:,:,1),dbg.DAF .cornersRGB(:,:,2),zeros(size(dbg.DAF .cornersRGB,1),size(dbg.DAF .cornersRGB,2)));
    pts = CBTools.slimNans(pts);
    invd = du.math.fitInverseDist(params.Krgbn,params.rgbDistort);
    pixsUndist = du.math.distortCam(reshape(pts(:,:,1:2),[],2)', params.Krgb, invd);
    ptsUndist = cat(3,reshape(pixsUndist',size(pts,1),size(pts,2),[]),pts(:,:,3));
    pts = ptsUndist;
    [resultsLineFit] = Validation.aux.get3DlineFitErrors(pts);
    lineFitRmsErrHor2dRGB(1,k) = resultsLineFit.lineFitRmsErrorTotal_h;
    lineFitRmsErrVer2dRGB(1,k) = resultsLineFit.lineFitRmsErrorTotal_v;
    lineFitMaxErrHor2dRGB(1,k) = resultsLineFit.lineFitMaxErrorTotal_h;
    lineFitMaxErrVer2dRGB(1,k) = resultsLineFit.lineFitMaxErrorTotal_v;
end
results.lineFitRmsErrHor2dRGB = nanmean(lineFitRmsErrHor2dRGB);
results.lineFitRmsErrVer2dRGB = nanmean(lineFitRmsErrVer2dRGB);
results.lineFitMaxRmsErrHor2dRGB = nanmax(lineFitRmsErrHor2dRGB);
results.lineFitMaxRmsErrVer2dRGB = nanmax(lineFitRmsErrVer2dRGB);
results.lineFitMaxErrHor2dRGB = nanmax(lineFitMaxErrHor2dRGB);
results.lineFitMaxErrVer2dRGB = nanmax(lineFitMaxErrVer2dRGB);
results.uvMapMeanRmse = nanmean(uvMapRmse);
results.uvMapMaxErr = nanmax(uvMapMaxErr);
results.uvMapMaxErr95 = nanmax(uvMapMaxErr95);
end