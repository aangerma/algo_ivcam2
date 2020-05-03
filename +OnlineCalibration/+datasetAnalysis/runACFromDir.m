function [sceneResults] = runACFromDir(sceneDir,params)
global runParams;
runParams.loadSingleScene = 1;
sceneResults = struct;
sceneResults.sceneFullPath = sceneDir;
[params] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir,params);
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);
[params] = OnlineCalibration.datasetAnalysis.getAugmentationParams(params);


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
currentFrame.z = frame.z(:,:,2);
currentFrame.i = frame.i(:,:,2);
currentFrame.yuy2 = frame.yuy2(:,:,2);

[currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(currentFrame,params,params.augmentOne);
originalParams = params;
sceneResults.originalParams = originalParams;

% Preprocess RGB
[currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);

if params.useOriginalEdgeDetection
    
    sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
    sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);

    % Preprocess IR
    [currentFrame.irEdge] = OnlineCalibration.aux.preprocessIR(currentFrame,params);
    % Preprocess Z
    [currentFrame.zEdge,currentFrame.zEdgeSupressed,currentFrame.zEdgeSubPixel,currentFrame.zValuesForSubEdges,currentFrame.dirI] = OnlineCalibration.aux.preprocessZ(currentFrame,params);
    % Turn to vertices
    [currentFrame.vertices,currentFrame.xim,currentFrame.yim] = OnlineCalibration.aux.subedges2vertices(currentFrame,params);
    [currentFrame.weights] = OnlineCalibration.aux.calculateWeights(currentFrame,params);
    [currentFrame.vertices] = OnlineCalibration.aux.subedges2vertices(currentFrame,params);
    currentFrame.weights = OnlineCalibration.aux.calculateWeights(currentFrame,params);
    currentFrame.sectionMapDepth = sectionMapDepth(currentFrame.zEdgeSupressed>0);
    currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);
%     figure(1);
%     imagesc(currentFrame.i);
%     hold on
%     plot(currentFrame.xim+1,currentFrame.yim+1,'r*');
else
    [currentFrame.irEdge,currentFrame.zEdge,...
        currentFrame.xim,currentFrame.yim,currentFrame.zValuesForSubEdges...
        ,currentFrame.zGradInDirection,currentFrame.dirPerPixel,currentFrame.weights,currentFrame.vertices,...
        currentFrame.sectionMapDepth] = OnlineCalibration.aux.preprocessDepth(currentFrame,params);
%     figure(1);
%     hold on
%     plot(currentFrame.xim+1,currentFrame.yim+1,'g*');
end

currentFrame.originalVertices = currentFrame.vertices;
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




sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,originalParams,0);
sceneResults.uvErrPostPOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsP,0);
sceneResults.uvErrPostKRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsKrgbRT,0);
sceneResults.uvErrPostKdepthRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsKdepthRT,0);

% 
% uvMapPre = OnlineCalibration.aux.projectVToRGB(currentFrame.originalVertices,originalParams.rgbPmat,originalParams.Krgb,originalParams.rgbDistort);
% uvMapPOpt = OnlineCalibration.aux.projectVToRGB(currentFrame.originalVertices,newParamsP.rgbPmat,newParamsP.Krgb,newParamsP.rgbDistort);
% vertices = ([currentFrame.xim,currentFrame.yim,ones(size(currentFrame.yim))] * pinv(newParamsKdepthRT.Kdepth)').*currentFrame.vertices(:,3);
% uvMapKdepthRT = OnlineCalibration.aux.projectVToRGB(vertices,newParamsKdepthRT.rgbPmat,newParamsKdepthRT.Krgb,newParamsKdepthRT.rgbDistort);



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
results = sceneResults;
end

