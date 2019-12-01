function [valResults ,allResults] = HVM_Val_Calc_int(frameBytes,sz,params,runParams,calibParams,fprintff,valResults)
    
%% get frames
    defaultDebug = 0;
    outFolder = fullfile(runParams.outputFolder,'Validation',[]);
    mkdirSafe(outFolder);
    debugMode = flip(dec2bin(uint16(defaultDebug),2)=='1');

%% load images
    im = Calibration.aux.convertBytesToFrames(frameBytes, sz, [], false);
    for i =1:1:size(im.i,3)
        frames(i).i = im.i(:,:,i);
        frames(i).z = im.z(:,:,i);
    end
    AvgIm.i = Calibration.aux.average_images(im.i);
    AvgIm.z = Calibration.aux.average_images(im.z);
    
%% DFZ
    Metrics = 'dfz';
    params.target.squareSize = calibParams.validationConfig.target.cbSquareSz;
    params.target.name = calibParams.validationConfig.target.name;
    params.expectedGridSize = calibParams.validationConfig.cbGridSz;
    params.sampleZFromWhiteCheckers = calibParams.validationConfig.sampleZFromWhiteCheckers;
    if params.sampleZFromWhiteCheckers
        params.cornersReferenceDepth = 'white';
    else
        params.cornersReferenceDepth = 'corners';
    end
    params.plainFitMaskIsRoiRect = calibParams.validationConfig.plainFitMaskIsRoiRect;
    params.gidMaskIsRoiRect = calibParams.validationConfig.gidMaskIsRoiRect;
    %average image 
    [dfzRes,allDfzRes,dbg] = Calibration.validation.DFZCalc(params,AvgIm,runParams,fprintff);
    valResults = Validation.aux.mergeResultStruct(valResults, dfzRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allDfzRes;
%% sharpness
    Metrics = 'sharpness';
    params.target.target = 'checkerboard_Iv2A1';
    [~, allSharpRes,dbg] = Validation.metrics.gridEdgeSharpIR(frames, params);
    sharpRes.horizontalSharpness = allSharpRes.horizMean;
    sharpRes.verticalSharpness = allSharpRes.vertMean;
    valResults = Validation.aux.mergeResultStruct(valResults, sharpRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allSharpRes;
%% temporalNoise
    Metrics = 'temporalNoise';
    tempNConfig = calibParams.validationConfig.(Metrics);
    params = Validation.aux.defaultMetricsParams();
    params.(Metrics) = tempNConfig.roi;
    [tns,allTnsResults] = Validation.metrics.zStd(frames, params);
    tnsRes.temporalNoise = tns;
    valResults = Validation.aux.mergeResultStruct(valResults, tnsRes);
    saveValidationData(allTnsResults,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allTnsResults;
%% ROI
    Metrics = 'roi';
%    [roiRes, frames,dbg] = Calibration.validation.validateROI(hw,calibParams,fprintff);
    [roiRes ,dbg] = Calibration.validation.ROICalc(AvgIm,calibParams,fprintff);
    valResults = Validation.aux.mergeResultStruct(valResults, roiRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = roiRes;
%% LOS
    Metrics = 'los';
%    losConfig = calibParams.validationConfig.(Metrics);
%    [losRes,allLosResults,frames,dbg] = Calibration.validation.validateLOS(hw,runParams,losConfig,calibParams.validationConfig.cbGridSz,fprintff);
    [losRes,allLosResults,dbg] = Calibration.validation.LOSCalc(frames,runParams,calibParams.validationConfig.cbGridSz,fprintff);
    valResults = Validation.aux.mergeResultStruct(valResults, losRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allLosResults;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function saveValidationData(debugData,frames,metric,outFolder,debugMode)
    
    % debug mode 1 indicates if we store the debug data of the metric
    if debugMode(1) && ~isempty(debugData)
        save(fullfile(outFolder,[metric '.mat']),'debugData');
    end
    
    % debug mode 2 indicates if we store the frames data of the metric
    if debugMode(2) && ~isempty(frames)
        f = fieldnames(frames);
        for i = 1:length(f)
            imfn = fullfile(dirname,strcat(metric,'Frame_',f{i},'.png'));
            imwrite(frames.(f{i}),imfn);
        end
    end
    
end