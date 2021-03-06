function [rgbPassed, rgbTable, results] = RGB_Calib_Calc_int(im, rgbs, calibParams, Kdepth, fprintff, runParams, z2mm,rgbCalTemperature, rgbThermalBinData)
    results = struct;
    rgbTable = [];
    rgbPassed = 0;
       
    [cbCorners,cornersValid,params] = Calibration.rgb.prepareData(im,rgbs,calibParams);
    
    if sum(cornersValid) < 3
        fprintff('[x] not enough valid views, skipping\n');
        return
    end
    res = Calibration.rgb.computeCal(cbCorners(cornersValid,:),Kdepth,params);
    rgbTable = Calibration.rgb.buildRGBTable(res,params,rgbCalTemperature);
    results.rgbIntReprojRms = res.color.rms;
    results.rgbExtReprojRms = res.extrinsics.rms;
    results.rgbYawDeg = Calibration.rgb.getYawFromRotationMat(res.extrinsics.r);
    %%
    params.camera = struct('zMaxSubMM',z2mm,'zK',Kdepth);
    params.camera.rgbPmat = res.color.k*[res.extrinsics.r res.extrinsics.t];
    params.rgbDistort = res.color.d;
    params.camera.rgbK = res.color.k;
    params.camera.Krgbn = res.color.Kn;
    params.target.target = 'checkerboard_Iv2A1';
    [resultsUvLf,~] = calcUVandLF( im, params, rgbs);
    results = Validation.aux.mergeResultStruct(results,resultsUvLf);
    %%
    rgbPassed = true;
    rgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Calibration_Info_CalibInfo', calibParams.tableVersions.rgbCalib);
    rgbTableFullPath = fullfile(runParams.outputFolder,'calibOutputFiles', rgbTableFileName);
    writeAllBytes(rgbTable.data, rgbTableFullPath);
    
    %%
    % Correct thermal table to RGB calibration temperature
    if isfield(calibParams.gnrl,'rgb') && isfield(calibParams.gnrl.rgb,'nBinsThermal')
        nBinsRgb = calibParams.gnrl.rgb.nBinsThermal;
    else
        nBinsRgb = 29;
    end
    rgbThermalData = Calibration.aux.convertRgbThermalBytesToData(rgbThermalBinData,nBinsRgb);
    [rgbThermalData] = Calibration.rgb.adjustRgbThermal2NewRefTemp(rgbThermalData,rgbCalTemperature,fprintff);
    if ~rgbThermalData.isValid
        rgbPassed = false;
    end        
    rgbThermalTable = single(reshape(rgbThermalData.thermalTable',[],1));
    rgbThermalTable = [rgbThermalData.minTemp; rgbThermalData.maxTemp; rgbThermalData.referenceTemp; rgbThermalTable];
    thermalRgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Thermal_Info_CalibInfo', calibParams.tableVersions.algoRgbThermal);
    thermalRgbTableFullPath = fullfile(runParams.outputFolder,'calibOutputFiles', thermalRgbTableFileName);
    Calibration.thermal.saveRgbThermalTable( rgbThermalTable , thermalRgbTableFullPath );
    fprintff('Generated algo thermal RGB table full path:\n%s\n',thermalRgbTableFullPath);
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
    frame.rgbI = rgbFrames{k};
    [~, resultsUvMap,dbg] = Validation.metrics.geomReprojectErrorUV(frame, params);
    
    uvMapRmse(1,k) = resultsUvMap.reproErrorUVPixRmsMeanAF;
    uvMapMaxErr(1,k) = resultsUvMap.reproErrorUVPixRmsMaxAF;
    uvMapMaxErr95(1,k) = resultsUvMap.maxErr95AF;

    pts = cat(3,dbg.DAF.cornersRGB(:,:,1),dbg.DAF.cornersRGB(:,:,2),zeros(size(dbg.DAF.cornersRGB,1),size(dbg.DAF .cornersRGB,2)));
    pts = CBTools.slimNans(pts);
    invd = du.math.fitInverseDist(params.camera.Krgbn,params.rgbDistort);
    pixsUndist = du.math.distortCam(reshape(pts(:,:,1:2),[],2)', params.camera.rgbK, invd);
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