function [results] = runACFromDirOverTime(sceneDir,params)
global runParams;
runParams.loadSingleScene = 0;
sceneResults = struct;
sceneResults.sceneFullPath = sceneDir;
[params] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir,params);
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);
[params] = OnlineCalibration.datasetAnalysis.getAugmentationParams(params);
% params.augmentationMaxMovement = 0;

frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir,1);%params.fileJump);

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

currentFrame.z = frame.z(:,:,1);
currentFrame.i = frame.i(:,:,1);
currentFrame.yuy2 = frame.yuy2(:,:,1);
[currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParamsSpecific(currentFrame,params);
currentFrame.yuy2Prev = currentFrame.yuy2;
load('C:\Users\mkiperwa\Downloads\movies\results\continous\depthScale\25_3_20_F9440687_SnapshotsLongRange_768X1024_RGB_1920X1080\startParams.mat');
params = bestParams;
[params] = OnlineCalibration.datasetAnalysis.getAugmentationParams(params);

originalParams = params;

for k = 2:numImages
    currentFrame.z = frame.z(:,:,k);
    currentFrame.i = frame.i(:,:,k);
    currentFrame.yuy2 = frame.yuy2(:,:,k);
    
    [currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParamsSpecific(currentFrame,params);
    sceneResults.originalParams = originalParams;
    
    % Preprocess RGB
    [currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);
    sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
    currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);
    
    % Preprocess IR
    [currentFrame.irEdge] = OnlineCalibration.aux.preprocessIR(currentFrame,params);
    % Preprocess Z
    [currentFrame.zEdge,currentFrame.zEdgeSupressed,currentFrame.zEdgeSubPixel,currentFrame.zValuesForSubEdges,currentFrame.dirI] = OnlineCalibration.aux.preprocessZAndIR(currentFrame,params);
    % Turn to vertices
    [currentFrame.vertices,currentFrame.xim,currentFrame.yim] = OnlineCalibration.aux.subedges2vertices(currentFrame,params);
    currentFrame.originalVertices = currentFrame.vertices;
    [currentFrame.weights] = OnlineCalibration.aux.calculateWeights(currentFrame,params);
    sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
    currentFrame.sectionMapDepth = sectionMapDepth(currentFrame.zEdgeSupressed>0);
    
    
    [~,desicionParams] = OnlineCalibration.aux.validScene(currentFrame,params);
    
    
    
    %     currentFrame.weights(:) = 1000;
    %     params.maxStepSize = 0.1;
    %     params.Trgb(1) = params.Trgb(1)-1.5;
    %% Perform Optimization
    desicionParams.initialCost = OnlineCalibration.aux.calculateCost(currentFrame.vertices,currentFrame.weights,currentFrame.rgbIDT,params);
    
    params.derivVar = 'KrgbRT';
    [newParamsKrgbRT,desicionParams.newCostKrgbRT] = OnlineCalibration.Opt.optimizeParameters(currentFrame,params);
    [~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsKrgbRT,originalParams,1);
    desicionParamsKrgbRT = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);
    
    params.derivVar = 'P';
    [newParamsP,desicionParams.newCostP] = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params);
    [~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsP,originalParams,1);
    desicionParamsP = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);
    
    params.derivVar = 'KdepthRT';
    [newParamsKdepthRT,desicionParams.newCostKdepthRT] = OnlineCalibration.Opt.optimizeParametersKdepthRT(currentFrame,params);
    [~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsKdepthRT,originalParams,1);
    desicionParamsKdepthRT = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);
    
    %
    
    
    sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,originalParams,0);
    sceneResults.uvErrPostPOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsP,0);
    sceneResults.uvErrPostKRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsKrgbRT,0);
    sceneResults.uvErrPostKdepthRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsKdepthRT,0);
    
    sceneResults.newParamsKrgbRT = newParamsKrgbRT;
    sceneResults.newParamsP = newParamsP;
    sceneResults.newParamsKdepthRT = newParamsKdepthRT;
    
    sceneResults.desicionParamsKrgbRT = desicionParamsKrgbRT;
    sceneResults.desicionParamsP = desicionParamsP;
    sceneResults.desicionParamsKdepthRT = desicionParamsKdepthRT;
    
    
    par.target.target = params.targetType;
    par.camera.zK = originalParams.Kdepth;
    par.camera.zMaxSubMM = originalParams.zMaxSubMM;
    par.target.squareSize = 30;
    sceneResults.gidPre = Validation.metrics.gridInterDistance(currentFrame, par);
    par.camera.zK = newParamsKdepthRT.Kdepth;
    sceneResults.gidPostKdepthRTOpt = Validation.metrics.gridInterDistance(currentFrame, par);
    currentFrame.yuy2Prev = currentFrame.yuy2;
    if ~contains(desicionParams.invalidReason,'Movement')
        params = newParamsKdepthRT;
    end
    results(k-1) = sceneResults;
end
end


