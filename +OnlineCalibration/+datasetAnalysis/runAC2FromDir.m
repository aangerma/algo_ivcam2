function [sceneResults] = runAC2FromDir(sceneDir,params)
global runParams;
runParams.loadSingleScene = 1;
sceneResults = struct;
sceneResults.sceneFullPath = fullfile(sceneDir,'Scene');
sceneResults.cbFullPath = fullfile(sceneDir,'CheckerBoard');
[params] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneResults.sceneFullPath,params);
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);
[params] = OnlineCalibration.datasetAnalysis.getAugmentationParams(params);
params.targetType = 'checkerboard_Iv2A1';

frame = OnlineCalibration.aux.loadZIRGBFrames(sceneResults.sceneFullPath);
frameCB = OnlineCalibration.aux.loadZIRGBFrames(sceneResults.cbFullPath);
frameCB.yuy2 = frameCB.yuy2(:,:,end);

currentFrame.yuy2Prev = frame.yuy2(:,:,1);
currentFrame.z = frame.z(:,:,end);
currentFrame.i = frame.i(:,:,end);
currentFrame.yuy2 = frame.yuy2(:,:,2);

[currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(currentFrame,params,params.augmentOne);
[frameCB,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(frameCB,params,params.augmentOne);
originalParams = params;
sceneResults.originalParams = originalParams;

% Preprocess RGB
[currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);

[currentFrame.irEdge,currentFrame.zEdge,...
    currentFrame.xim,currentFrame.yim,currentFrame.zValuesForSubEdges...
    ,currentFrame.zGradInDirection,currentFrame.dirPerPixel,currentFrame.weights,currentFrame.vertices,...
    currentFrame.sectionMapDepth] = OnlineCalibration.aux.preprocessDepth(currentFrame,params);
%     figure(1);
%     hold on
%     plot(currentFrame.xim+1,currentFrame.yim+1,'g*');


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

% params.Kdepth([1,5]) = params.Kdepth([1,5]) ./newParamsKrgbRT.Krgb([1,5]).*params.Krgb([1,5]);
params.Kdepth([1,5]) = params.Kdepth([1,5]) ./newParamsP.rgbPmat([1,5]).*params.rgbPmat([1,5]);
params.derivVar = 'KdepthRTKrgb';
[newParamsKdepthRT,desicionParams.newCostKdepthRT] = OnlineCalibration.Opt.optimizeParametersKdepthRT(currentFrame,params);
[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsKdepthRT,originalParams,1);
desicionParamsKdepthRT = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);




sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,originalParams,0);
sceneResults.uvErrPostPOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsP,0);
sceneResults.uvErrPostKRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKrgbRT,0);
sceneResults.uvErrPostKdepthRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKdepthRT,0);

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
sceneResults.metricsPre = runGeometricMetrics(frameCB, par);
par.camera.zK = newParamsKdepthRT.Kdepth;
sceneResults.metricsPost = runGeometricMetrics(frameCB, par);
end

function metrics = runGeometricMetrics(frame,par)
    metrics.gid = Validation.metrics.gridInterDistance(frame, par);
    [~,results2D] = Validation.metrics.grid2DLineFit(frame, par);
    metrics.lineFitRms2D_H = results2D.lineFit2DHorizontalErrorRmsAF;
    metrics.lineFitRms2D_V = results2D.lineFit2DHorizontalErrorRmsAF;
    metrics.lineFitMax2D_H = results2D.lineFit2DMaxErrorTotal_hAF;
    metrics.lineFitMax2D_V = results2D.lineFit2DMaxErrorTotal_vAF;
    [~,results3D] = Validation.metrics.gridLineFit(frame, par);
    metrics.lineFitRms3D_H = results3D.lineFitHorizontalErrorRmsAF;
    metrics.lineFitRms3D_V = results3D.lineFitVerticalErrorRmsAF;
    metrics.lineFitMax3D_H = results3D.lineFitMaxErrorTotal_hAF;
    metrics.lineFitMax3D_V = results3D.lineFitMaxErrorTotal_vAF;
    [~,resultsDist] = Validation.metrics.gridDistortion(frame, par);
    metrics.lineFitRms3D_H = resultsDist.horzErrorMeanAF;
    metrics.lineFitRms3D_V = resultsDist.vertErrorMeanAF;
    
    
end


