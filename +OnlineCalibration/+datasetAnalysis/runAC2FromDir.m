function [sceneResults] = runAC2FromDir(sceneDir,params)
global runParams;
runParams.loadSingleScene = 1;
sceneResults = struct;
sceneResults.sceneFullPath = fullfile(sceneDir,'Scene');
sceneResults.cbFullPath = fullfile(sceneDir,'CheckerBoard');
if contains(sceneDir,'aged')
    load(fullfile(sceneResults.sceneFullPath,'cameraParams.mat'));
    params = mergestruct(params,cameraParams);
else
    [params] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneResults.sceneFullPath,params);
end
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);
[params] = OnlineCalibration.datasetAnalysis.getAugmentationParams(params);
params.targetType = 'checkerboard_Iv2A1';
if contains(sceneDir,'aged')
    params.serial = 'F9440656';
else
    params.serial = strsplit(sceneDir,'\'); params.serial = params.serial{end-2};
end
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


% params.derivVar = 'Pthermal';
% inputParams.fromFile = 1;
% inputParams.tablePath = OnlineCalibration.aux.getRgbThermalTablePathAc(sceneDir);
% [params.rgbTmat] = OnlineCalibration.aux.getRgbThermalCorrectionMat(inputParams,params.captureHumT);
% params.rgbTfix = 1;
% [newParamsPthermal,desicionParams.newCostPthermal] = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params);
% [~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsPthermal,originalParams,1);
% desicionParamsPthermal = Validation.aux.mergeResultStruct(desicionParams, validOutputStruct);
% params.rgbTfix = 0;


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

% newParamsKzFromPthermal = newParamsPthermal;
% newParamsKzFromPthermal.derivVar = 'Kdepth';
% [newParamsKzFromPthermal.Krgb,newParamsKzFromPthermal.Rrgb,newParamsKzFromPthermal.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsKzFromPthermal.rgbPmat);
% newParamsKzFromPthermal.Krgb(1,2) = 0;
% newParamsKzFromPthermal.Kdepth([1,5]) = newParamsKzFromPthermal.Kdepth([1,5])./newParamsKzFromPthermal.Krgb([1,5]).*params.Krgb([1,5]);
% newParamsKzFromPthermal.Krgb([1,5]) = originalParams.Krgb([1,5]);
% newParamsKzFromPthermal.rgbPmat = newParamsKzFromPthermal.Krgb*[newParamsKzFromPthermal.Rrgb,newParamsKzFromPthermal.Trgb];


sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,originalParams,0);
sceneResults.uvErrPostPOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsP,0);
% sceneResults.uvErrPostKRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKrgbRT,0);
% sceneResults.uvErrPostKdepthRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKdepthRT,0);
sceneResults.uvErrPostKzFromPOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKzFromP,0);
% sceneResults.uvErrPostPthermalOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsPthermal,0);
% sceneResults.uvErrPostKzFromPthermalOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKzFromPthermal,0);

% uvMapPre = OnlineCalibration.aux.projectVToRGB(currentFrame.originalVertices,originalParams.rgbPmat,originalParams.Krgb,originalParams.rgbDistort);
% uvMapPOpt = OnlineCalibration.aux.projectVToRGB(currentFrame.originalVertices,newParamsP.rgbPmat,newParamsP.Krgb,newParamsP.rgbDistort);
% vertices = ([currentFrame.xim,currentFrame.yim,ones(size(currentFrame.yim))] * pinv(newParamsKdepthRT.Kdepth)').*currentFrame.vertices(:,3);
% uvMapKdepthRT = OnlineCalibration.aux.projectVToRGB(vertices,newParamsKdepthRT.rgbPmat,newParamsKdepthRT.Krgb,newParamsKdepthRT.rgbDistort);
% vertices = ([currentFrame.xim,currentFrame.yim,ones(size(currentFrame.yim))] * pinv(newParamsKzFromP.Kdepth)').*currentFrame.vertices(:,3);
% uvMapPostKzFromPOpt = OnlineCalibration.aux.projectVToRGB(vertices,newParamsKzFromP.rgbPmat,newParamsKzFromP.Krgb,newParamsKzFromP.rgbDistort);



% sceneResults.newParamsKrgbRT = newParamsKrgbRT;
sceneResults.newParamsP = newParamsP;
% sceneResults.newParamsPthermal = newParamsPthermal;
% sceneResults.newParamsKdepthRT = newParamsKdepthRT;
sceneResults.newParamsKzFromP = newParamsKzFromP;
% sceneResults.newParamsKzFromPthermal = newParamsKzFromPthermal;


% sceneResults.desicionParamsKrgbRT = desicionParamsKrgbRT;
sceneResults.desicionParamsP = desicionParamsP;
% sceneResults.desicionParamsPthermal = desicionParamsPthermal;
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
% par.camera.zK = newParamsKzFromPthermal.Kdepth;
% sceneResults.metricsPostKzFromPthermal = runGeometricMetrics(frameCB, par);

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
    acDataIn.flags = 2;
    
    KRaw = params.Kdepth;
    KRaw(1,3) = single(params.depthRes(2))-1-KRaw(1,3);
    KRaw(2,3) = single(params.depthRes(1))-1-KRaw(2,3);

    newKRaw = newKdepth;
    newKRaw(1,3) = single(params.depthRes(2))-1-newKRaw(1,3);
    newKRaw(2,3) = single(params.depthRes(1))-1-newKRaw(2,3);

    preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acDataIn, dsmRegs, params.depthRes, KRaw, rot90(currentFrame.relevantPixelsImage,2));
    [losShift, losScaling] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, newKRaw);
    newAcDataStruct = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, acDataIn.flags, losShift, losScaling);
    newAcDataStruct.flags(2:6) = uint8(0);

    
    sceneResults.newAcDataStruct = newAcDataStruct;
    sceneResults.losShift = losShift;
    sceneResults.losScaling = losScaling;
    dsmFixscales = -(1-[newAcDataStruct.hFactor,newAcDataStruct.vFactor])*100;
    dsmFixOffsets = [newAcDataStruct.hOffset,newAcDataStruct.vOffset];
    
    warper = OnlineCalibration.Aug.fetchDsmWarper(params.serial,params.depthRes,dsmFixscales(1),dsmFixscales(2));
    frameCBFixed = warper.ApplyWarp(frameCB,1);
    
    sceneResults.uvErrPostK2DSMOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCBFixed,newParamsK2DSM,0);
    par.camera.zK = newParamsK2DSM.Kdepth;
    sceneResults.metricsPostK2DSM = runGeometricMetrics(frameCBFixed, par);

    
    %% Without Scale quantization
    DSMWrapper = OnlineCalibration.Aug.FrameDsmWarper(params.accPath);
    DSMWrapper = DSMWrapper.SetRes(double(params.depthRes));
    DSMWrapper = DSMWrapper.SetDsmWarp([1+dsmFixscales(1)/100,0],[1+dsmFixscales(2)/100,0]);
    frameCBFixed = DSMWrapper.ApplyWarp(frameCB,1);
    sceneResults.uvErrPostK2DSMOptNoQuant = OnlineCalibration.Metrics.calcUVMappingErr(frameCBFixed,newParamsK2DSM,0);
    par.camera.zK = newParamsK2DSM.Kdepth;
    sceneResults.metricsPostK2DSMNoQuant = runGeometricMetrics(frameCBFixed, par);
    
    %% With offset as well 
    Offsets = 2047.*([newAcDataStruct.hFactor,newAcDataStruct.vFactor]-1)+[dsmRegs.dsmXscale,dsmRegs.dsmYscale].*[dsmRegs.dsmXoffset,dsmRegs.dsmYoffset].*(1-[newAcDataStruct.hFactor,newAcDataStruct.vFactor]);
%     DSMWrapper = DSMWrapper.SetDsmWarp([1+dsmFixscales(1)/100,dsmFixOffsets(1)],[1+dsmFixscales(2)/100,dsmFixOffsets(2)]);
    DSMWrapper = DSMWrapper.SetDsmWarp([newAcDataStruct.hFactor,Offsets(1)],[newAcDataStruct.vFactor,Offsets(2)]);
    frameCBFixed = DSMWrapper.ApplyWarp(frameCB,1);
    sceneResults.uvErrPostK2DSMOptNoQuantPlusOffset = OnlineCalibration.Metrics.calcUVMappingErr(frameCBFixed,newParamsK2DSM,0);
    par.camera.zK = newParamsK2DSM.Kdepth;
    sceneResults.metricsPostK2DSMNoQuantPlusOffset = runGeometricMetrics(frameCBFixed, par);
   
    
    %% Least Squares of DSM reports
    %% Rotate image and K to be in camera coordiantes
    verticesOrig = ([currentFrame.xim,currentFrame.yim,ones(size(currentFrame.yim))] * pinv(params.Kdepth)').*currentFrame.vertices(:,3);
    verticesNew = ([currentFrame.xim,currentFrame.yim,ones(size(currentFrame.yim))] * pinv(newParamsKzFromP.Kdepth)').*currentFrame.vertices(:,3);
    verticesOrig(:,1:2) = -verticesOrig(:,1:2);
    verticesNew(:,1:2) = -verticesNew(:,1:2);
    %% Calculate RPT orig for valid points
    rptOrig = Utils.convert.RptToVertices(verticesOrig, regs, [], 'inverse');
    rptNew = Utils.convert.RptToVertices(verticesNew, regs, [], 'inverse');
    [dsmXcoeff] = single(polyfit(rptOrig(:,2), rptNew(:,2), 1));
    [dsmYcoeff] = single(polyfit(rptOrig(:,3), rptNew(:,3), 1));
    DSMWrapper = DSMWrapper.SetDsmWarp(dsmXcoeff,dsmYcoeff);
    frameCBFixed = DSMWrapper.ApplyWarp(frameCB,1);
    sceneResults.uvErrPostK2DSMOptLS = OnlineCalibration.Metrics.calcUVMappingErr(frameCBFixed,newParamsK2DSM,0);
    par.camera.zK = newParamsK2DSM.Kdepth;
    sceneResults.metricsPostK2DSMLS = runGeometricMetrics(frameCBFixed, par);

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


