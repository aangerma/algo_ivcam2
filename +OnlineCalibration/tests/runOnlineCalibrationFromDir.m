function [results] = runOnlineCalibrationFromDir(sceneDir,params)
global sceneResults;
sceneResults = struct;
sceneResults.sceneFullPath = sceneDir;
outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images

[params] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir,params);
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);

originalParams = params;
sceneResults.originalParams = originalParams;
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir);

numImages = min([size(frame.yuy2,3),size(frame.z,3),size(frame.i,3)]);
if numImages < 2
    disp(['Not enough RGB frames in: ' num2str(sceneDir)]);
    if numImages == 1
        disp('Duplicating RGB image');
        frame.z(:,:,2) = frame.z(:,:,1);frame.i(:,:,2) = frame.i(:,:,1);frame.yuy2(:,:,2) = frame.yuy2(:,:,1);
        numImages = 2;
    else
        return;
    end
end
currentFrame.yuy2Prev = frame.yuy2(:,:,1);
for k = 2:numImages
    currentFrame.z = frame.z(:,:,k);
    currentFrame.i = frame.i(:,:,k);
    currentFrame.yuy2 = frame.yuy2(:,:,k);
    
    if isfield(params,'saveBinIm') && params.saveBinIm
        % Save Inputs
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(currentFrame.z),'uint16');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(currentFrame.i),'uint8');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(currentFrame.yuy2),'uint8');
    end
    
    % Preprocess RGB
    [currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);
    sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
    currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);
    if isfield(params,'saveBinIm') && params.saveBinIm
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',single(currentFrame.rgbEdge),'single');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',single(currentFrame.rgbIDT),'single');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',single(currentFrame.rgbIDTx),'single');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',single(currentFrame.rgbIDTy),'single');
    end
    
    % Preprocess IR
    [currentFrame.irEdge] = OnlineCalibration.aux.preprocessIR(currentFrame,params);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_edge',single(currentFrame.irEdge),'single');
    
    % Preprocess Z
    % [currentFrame.zEdge,currentFrame.zEdgeSupressed,currentFrame.zEdgeSubPixel,currentFrame.zValuesForSubEdges,frame.dirI] = OnlineCalibration.aux.preprocessZ(currentFrame,params);
    [currentFrame.zEdge,currentFrame.zEdgeSupressed,currentFrame.zEdgeSubPixel,currentFrame.zValuesForSubEdges,currentFrame.dirI] = OnlineCalibration.aux.preprocessZAndIR(currentFrame,params);
    if isfield(params,'saveBinIm') && params.saveBinIm
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',single(currentFrame.zEdge),'single');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSubPixel',single(currentFrame.zEdgeSubPixel),'single');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSupressed',single(currentFrame.zEdgeSupressed),'single');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_valuesForSubEdges',single(currentFrame.zValuesForSubEdges),'single');
    end
    
    [currentFrame.vertices,currentFrame.xim,currentFrame.yim] = OnlineCalibration.aux.subedges2vertices(currentFrame,params);
    currentFrame.originalVertices = currentFrame.vertices;
    [currentFrame.weights] = OnlineCalibration.aux.calculateWeights(currentFrame,params);
    sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
    currentFrame.sectionMapDepth = sectionMapDepth(currentFrame.zEdgeSupressed>0);
    if isfield(params,'saveBinIm') && params.saveBinIm
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(currentFrame.vertices),'single');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weights',single(currentFrame.weights),'single');
    end
    
    if ~OnlineCalibration.aux.validScene(currentFrame,params)
        disp('Scene not valid!');
        if ~OnlineCalibration.Globals.getIgnoreSceneInvalidationFlag
            continue;
        end
    end
    
    %% Perform Optimization
    params.derivVar = 'KrgbRT';
    [newParams,newCost] = OnlineCalibration.Opt.optimizeParameters(currentFrame,params);
    params.derivVar = 'P';
    [newParamsP,newCostP] = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params);
    params.derivVar = 'KdepthRT';
    [newParamsKdepthRT,newCostKdepthRT] = OnlineCalibration.Opt.optimizeParametersKdepthRT(currentFrame,params);
    
    %     [validParams,newParamsFixed,dbg] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParams,originalParams,k);
    [validParams,newParamsFixed,dbg] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsKdepthRT,originalParams,k);
    if ~OnlineCalibration.Globals.getIgnoreOutputValidationFlag()
        if validParams
            %             newParams = newParamsFixed;
        else
            currentFrame.yuy2Prev = currentFrame.yuy2;
            continue;
        end
    end
    %
    try
        if isfield(params,'doPlot')
            doPlot = params.doPlot;
        else
            doPlot = 0;
        end
        
        sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,originalParams,doPlot);
        if doPlot
            ax = gca;
            title({ax.Title.String;'Original UV error'});
        end
        sceneResults.uvErrPostPOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsP,doPlot);
        if doPlot
            ax = gca;
            title({ax.Title.String;'After P optimization'});
        end
        sceneResults.uvErrPostKRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParams,doPlot);
        if doPlot
            ax = gca;
            title({ax.Title.String;'After KrgbRT optimization'});
        end
        sceneResults.uvErrPostKdepthRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsKdepthRT,doPlot);
        if doPlot
            ax = gca;
            title({ax.Title.String;'After KdepthbRT optimization'});
        end
    catch e
        sceneResults.errorMessage = e.message;
        sceneResults.uvErrPre = inf;
        sceneResults.uvErrPostPOpt = inf;
        sceneResults.uvErrPostKRTOpt = inf;
        sceneResults.uvErrPostKdepthRTOpt = inf;
        disp([e.identifier ' '  e.message 'in ' sceneDir ', continuing to next image...']);
    end
    
    par.target.target = params.targetType;
    par.camera.zK = originalParams.Kdepth;
    par.camera.zMaxSubMM = originalParams.zMaxSubMM;
    par.target.squareSize = 30;
    sceneResults.gidPre = Validation.metrics.gridInterDistance(currentFrame, par);
    par.camera.zK = newParamsKdepthRT.Kdepth;
    sceneResults.gidPostKdepthRTOpt = Validation.metrics.gridInterDistance(currentFrame, par);
    
    params = newParams;
    currentFrame.yuy2Prev = currentFrame.yuy2;
    results(k-1) = sceneResults;
end
end

