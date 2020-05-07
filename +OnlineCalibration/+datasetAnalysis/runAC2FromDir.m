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
params.serial = strsplit(sceneDir,'\'); params.serial = params.serial{end-2};
[params.atcPath,params.accPath,params.calPathValid] = OnlineCalibration.aux.serialToCalDirs(params.serial);
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneResults.sceneFullPath,[]);
frameCB = OnlineCalibration.aux.loadZIRGBFrames(sceneResults.cbFullPath,[]);
frameCB.yuy2 = frameCB.yuy2(:,:,end);

currentFrame.yuy2Prev = frame.yuy2(:,:,1);
currentFrame.z = frame.z(:,:,end);
currentFrame.i = frame.i(:,:,end);
currentFrame.yuy2 = frame.yuy2(:,:,2);

[currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(currentFrame,params,params.augMethod);
[frameCB,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(frameCB,params,params.augMethod);
originalParams = params;
sceneResults.originalParams = originalParams;

% Preprocess RGB
[currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);

[currentFrame.irEdge,currentFrame.zEdge,...
    currentFrame.xim,currentFrame.yim,currentFrame.zValuesForSubEdges...
    ,currentFrame.zGradInDirection,currentFrame.dirPerPixel,currentFrame.weights,currentFrame.vertices,...
    currentFrame.sectionMapDepth,currentFrame.relevantPixelsImage] = OnlineCalibration.aux.preprocessDepth(currentFrame,params);


currentFrame.originalVertices = currentFrame.vertices;
[~,desicionParams,isMovement] = OnlineCalibration.aux.validScene(currentFrame,params);

    

%     currentFrame.weights(:) = 1000;
%     params.maxStepSize = 0.1;
%     params.Trgb(1) = params.Trgb(1)-1.5;
%% Perform Optimization
desicionParams.initialCost = OnlineCalibration.aux.calculateCost(currentFrame.vertices,currentFrame.weights,currentFrame.rgbIDT,params);

% params.derivVar = 'KrgbRT';
% [newParamsKrgbRT,desicionParams.newCostKrgbRT] = OnlineCalibration.Opt.optimizeParameters(currentFrame,params);

params.derivVar = 'P';
[newParamsP,desicionParams.newCost] = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params);
[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsP,originalParams,1);
desicionParamsP = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);

params.derivVar = 'Pthermal';
inputParams.fromFile = 1;
inputParams.tablePath = OnlineCalibration.aux.getRgbThermalTablePathAc(sceneDir);
[params.rgbTmat] = OnlineCalibration.aux.getRgbThermalCorrectionMat(inputParams,params.captuteHumT);
params.rgbTfix = 1;
[newParamsPthermal,desicionParams.newCostPthermal] = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params);
[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsPthermal,originalParams,1);
desicionParamsPthermal = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);
params.rgbTfix = 0;


% params.Kdepth([1,5]) = params.Kdepth([1,5]) ./newParamsKrgbRT.Krgb([1,5]).*params.Krgb([1,5]);
% params.Kdepth([1,5]) = params.Kdepth([1,5]) ./newParamsP.rgbPmat([1,5]).*params.rgbPmat([1,5]);
% params.derivVar = 'KdepthRTKrgb';
% [newParamsKdepthRT,desicionParams.newCostKdepthRT] = OnlineCalibration.Opt.optimizeParametersKdepthRT(currentFrame,params);
% [~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsKdepthRT,originalParams,1);
% desicionParamsKdepthRT = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);


newParamsKzFromP = newParamsP;
newParamsKzFromP.derivVar = 'Kdepth';
[newParamsKzFromP.Krgb,newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsKzFromP.rgbPmat);
newParamsKzFromP.Krgb(1,2) = 0;
newParamsKzFromP.Kdepth([1,5]) = newParamsKzFromP.Kdepth([1,5])./newParamsKzFromP.Krgb([1,5]).*params.Krgb([1,5]);
newParamsKzFromP.Krgb([1,5]) = originalParams.Krgb([1,5]);
newParamsKzFromP.rgbPmat = newParamsKzFromP.Krgb*[newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb];

newParamsKzFromPthermal = newParamsPthermal;
newParamsKzFromPthermal.derivVar = 'Kdepth';
[newParamsKzFromPthermal.Krgb,newParamsKzFromPthermal.Rrgb,newParamsKzFromPthermal.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsKzFromPthermal.rgbPmat);
newParamsKzFromPthermal.Krgb(1,2) = 0;
newParamsKzFromPthermal.Kdepth([1,5]) = newParamsKzFromPthermal.Kdepth([1,5])./newParamsKzFromPthermal.Krgb([1,5]).*params.Krgb([1,5]);
newParamsKzFromPthermal.Krgb([1,5]) = originalParams.Krgb([1,5]);
newParamsKzFromPthermal.rgbPmat = newParamsKzFromPthermal.Krgb*[newParamsKzFromPthermal.Rrgb,newParamsKzFromPthermal.Trgb];


sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,originalParams,0);
sceneResults.uvErrPostPOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsP,0);
% sceneResults.uvErrPostKRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKrgbRT,0);
% sceneResults.uvErrPostKdepthRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKdepthRT,0);
sceneResults.uvErrPostKzFromPOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKzFromP,0);
sceneResults.uvErrPostPthermalOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsPthermal,0);
sceneResults.uvErrPostKzFromPthermalOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKzFromPthermal,0);


% 
% uvMapPre = OnlineCalibration.aux.projectVToRGB(currentFrame.originalVertices,originalParams.rgbPmat,originalParams.Krgb,originalParams.rgbDistort);
% uvMapPOpt = OnlineCalibration.aux.projectVToRGB(currentFrame.originalVertices,newParamsP.rgbPmat,newParamsP.Krgb,newParamsP.rgbDistort);
% vertices = ([currentFrame.xim,currentFrame.yim,ones(size(currentFrame.yim))] * pinv(newParamsKdepthRT.Kdepth)').*currentFrame.vertices(:,3);
% uvMapKdepthRT = OnlineCalibration.aux.projectVToRGB(vertices,newParamsKdepthRT.rgbPmat,newParamsKdepthRT.Krgb,newParamsKdepthRT.rgbDistort);
% vertices = ([currentFrame.xim,currentFrame.yim,ones(size(currentFrame.yim))] * pinv(newParamsKzFromP.Kdepth)').*currentFrame.vertices(:,3);
% uvMapPostKzFromPOpt = OnlineCalibration.aux.projectVToRGB(vertices,newParamsKzFromP.rgbPmat,newParamsKzFromP.Krgb,newParamsKzFromP.rgbDistort);



% sceneResults.newParamsKrgbRT = newParamsKrgbRT;
sceneResults.newParamsP = newParamsP;
sceneResults.newParamsPthermal = newParamsPthermal;
% sceneResults.newParamsKdepthRT = newParamsKdepthRT;
sceneResults.newParamsKzFromP = newParamsKzFromP;
sceneResults.newParamsKzFromPthermal = newParamsKzFromPthermal;


% sceneResults.desicionParamsKrgbRT = desicionParamsKrgbRT;
sceneResults.desicionParamsP = desicionParamsP;
sceneResults.desicionParamsPthermal = desicionParamsPthermal;
sceneResults.desicionParamsKzFromP = desicionParamsP;

sceneResults.validFixBySVM = OnlineCalibration.aux.validBySVM(sceneResults.desicionParamsKzFromP,newParamsKzFromP);
sceneResults.validMovement = ~isMovement;

par.target.target = params.targetType;
par.camera.zK = originalParams.Kdepth;
par.camera.zMaxSubMM = originalParams.zMaxSubMM;
par.target.squareSize = 30;
sceneResults.metricsPre = runGeometricMetrics(frameCB, par);
% par.camera.zK = newParamsKdepthRT.Kdepth;
% sceneResults.metricsPost = runGeometricMetrics(frameCB, par);
par.camera.zK = newParamsKzFromP.Kdepth;
sceneResults.metricsPostKzFromP = runGeometricMetrics(frameCB, par);
par.camera.zK = newParamsKzFromPthermal.Kdepth;
sceneResults.metricsPostKzFromPthermal = runGeometricMetrics(frameCB, par);

%% Apply fix in DSM instead of changing Kdepth
if params.calPathValid && params.applyK2DSMFix
    calData = Calibration.tables.getCalibDataFromCalPath(params.atcPath, params.accPath);
    regsDEST.hbaseline = 0;
    regsDEST.baseline = -10;
    regsDEST.baseline2 = regsDEST.baseline^2;
    regs = calData.regs;
    regs.DEST = mergestruct(regs.DEST, regsDEST);

    dsmRegs = calData.regs.EXTL;
    newKdepth = newParamsKzFromP.Kdepth;
    newParamsK2DSM = newParamsKzFromP;
    newParamsK2DSM.Kdepth = params.Kdepth;
    acDataIn = OnlineCalibration.aux.defaultACTable();
    
    KRaw = params.Kdepth;
    KRaw(1,3) = single(params.depthRes(2))-1-KRaw(1,3);
    KRaw(2,3) = single(params.depthRes(1))-1-KRaw(2,3);

    newKRaw = newKdepth;
    newKRaw(1,3) = single(params.depthRes(2))-1-newKRaw(1,3);
    newKRaw(2,3) = single(params.depthRes(1))-1-newKRaw(2,3);

    preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acDataIn, dsmRegs, params.depthRes, KRaw);
    [losShift, losScaling] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, currentFrame.relevantPixelsImage, KRaw, newKRaw);
    newAcDataStruct = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, acDataIn.flags, losShift, losScaling);
    newAcDataStruct.flags(2:6) = uint8(0);

    
    sceneResults.newAcDataStruct = newAcDataStruct;
    sceneResults.losShift = losShift;
    sceneResults.losScaling = losScaling;
    dsmFixscales = (1-sceneResults.losScaling)*100;
    warper = OnlineCalibration.Aug.fetchDsmWarper(params.serial,params.depthRes,dsmFixscales(1),dsmFixscales(2));
    frameCBFixed = warper.ApplyWarp(frameCB);
    
    sceneResults.uvErrPostK2DSMOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCBFixed,newParamsK2DSM,0);
    par.camera.zK = newParamsK2DSM.Kdepth;
    sceneResults.metricsPostK2DSM = runGeometricMetrics(frameCBFixed, par);

end

end

function metrics = runGeometricMetrics(frame,par)
    metrics.gid = Validation.metrics.gridInterDistance(frame, par);
    [~,resultsLF] = Validation.metrics.gridLineFit(frame, par);
    metrics.lineFitRms3D_H = resultsLF.lineFitRmsErrorTotal_hAF;
    metrics.lineFitRms3D_V = resultsLF.lineFitRmsErrorTotal_vAF;
    metrics.lineFitMax3D_H = resultsLF.lineFitMaxErrorTotal_hAF;
    metrics.lineFitMax3D_V = resultsLF.lineFitMaxErrorTotal_vAF;
    metrics.lineFitRms2D_H = resultsLF.lineFit2DRmsErrorTotal_hAF;
    metrics.lineFitRms2D_V = resultsLF.lineFit2DRmsErrorTotal_vAF;
    metrics.lineFitMax2D_H = resultsLF.lineFit2DMaxErrorTotal_hAF;
    metrics.lineFitMax2D_V = resultsLF.lineFit2DMaxErrorTotal_vAF;
    [~,resultsDist] = Validation.metrics.gridDistortion(frame, par);
    metrics.lineFitRms3D_H = resultsDist.horzErrorMeanAF;
    metrics.lineFitRms3D_V = resultsDist.vertErrorMeanAF;
    
    
end


