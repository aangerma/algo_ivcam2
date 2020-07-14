function [sceneResults] = runIterativeAC2FromDirAtvs(sceneDir,params)
global runParams;
runParams.loadSingleScene = 1;

sceneResults = struct;
% sceneResults.sceneFullPath = fullfile(sceneDir,'Scene');
% sceneResults.cbFullPath = fullfile(sceneDir,'CheckerBoard');
sceneResults.sceneFullPath = sceneDir;
frame = OnlineCalibration.aux.loadZIRGBFramesAtv(sceneResults.sceneFullPath);
frameCB = frame;
params.depthRes = size(frame.i);
params.rgbRes = fliplr(size(frame.yuy2));
strsplitTemp = strsplit(sceneDir,'\');
sceneResults.atvDataPath = fullfile(strsplitTemp{1:end-3},'Matlab\mat_files');
runIx = strsplit(sceneDir,'cycle');
runIx = str2double(runIx{end})+1;
[params] = OnlineCalibration.aux.getCameraParamsFromAtvRun(sceneResults.atvDataPath,params,runIx);
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);
[params] = OnlineCalibration.datasetAnalysis.getAugmentationParams(params);
params.targetType = 'checkerboard_Iv2A1';
params.serial = strsplit(sceneDir,'\'); params.serial = params.serial{end-4};
[params.atcPath,params.accPath,params.calPathValid] = OnlineCalibration.aux.serialToCalDirs(params.serial);

currentFrame.yuy2Prev = frame.yuy2;
currentFrame.z = frame.z;
currentFrame.i = frame.i;
currentFrame.yuy2 = frame.yuy2;
currentFrame.yuy2FromLastSuccess = zeros(size(currentFrame.yuy2));

if isfield(params,'correctThermal') &&  params.correctThermal
    params.thermalInputParams.fromFile = 1;
    params.thermalInputParams.tablePath = OnlineCalibration.aux.getRgbThermalTablePathAc(sceneDir,1);
    [params.rgbTmat,params.referenceTemp] = OnlineCalibration.aux.getRgbThermalCorrectionMat(params.thermalInputParams,params.captureHumT);
    [params.rgbPmat,params.Krgb] = OnlineCalibration.aux.correctThermalScale(params.Krgb,params.Rrgb,params.Trgb,params.rgbTmat(1,1));
end

[sceneResults.uvErrPreWithoutAug] = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,params,0);
[sceneResults.metricsPreWithoutAug] = OnlineCalibration.aux.runGeometricMetrics(frameCB, params);

[currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(currentFrame,params,params.augMethod);
[frameCB,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(frameCB,params,params.augMethod);
originalParams = params;
sceneResults.originalParams = originalParams;


load(fullfile(sceneResults.atvDataPath,'validationCalcAfterHeating_in.mat'),'data');
regs = data.regs;
dsmRegsOrig = data.regs.EXTL;
if ~isfield(params,'acData')
    acData = OnlineCalibration.aux.defaultACTable();
    acData.flags = 1;
    dsmRegs = dsmRegsOrig;
else
    acData = params.acData;
    dsmRegs = Utils.convert.applyAcResOnDsmModel(acData, dsmRegsOrig, 'direct');
end
sceneResults.acDataIn = acData;

[~,cbVertices] = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,originalParams,0);
[cbVertices,xcb,ycb] = OnlineCalibration.K2DSM.updateVerticesWithNewDSM(cbVertices,regs,dsmRegsOrig,dsmRegs,params.Kdepth);
sceneResults.cbVerticesInit = cbVertices;
sceneResults.cbVerticesPost = cbVertices;
sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,originalParams,0,cbVertices');
[sceneResults.gidPre,sceneResults.scaleErrorHPre,sceneResults.scaleErrorVPre] = OnlineCalibration.Metrics.gidAndScaleFromVerts(cbVertices,30,[20,28]);
currentFrame = OnlineCalibration.aux.preprocess(currentFrame,params);
[currentFrame.vertices,currentFrame.xim,currentFrame.yim] = OnlineCalibration.K2DSM.updateVerticesWithNewDSM(currentFrame.vertices,regs,dsmRegsOrig,dsmRegs,params.Kdepth);

currentFrameCand = currentFrame;
newParamsK2DSMCand = params;
converged = false;
iterNum = 0;
% Calculate input validity params cost
[~,decisionParams,isMovement,isMovementFromLastSuccess] = OnlineCalibration.aux.validScene(currentFrameCand,params);
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(currentFrameCand.vertices,currentFrameCand.weights,currentFrameCand.rgbIDT,params);
lastCost = decisionParams.initialCost;
dsmRegsCand = dsmRegs;
acDataCand = acData;

[~,newParamsPTemp,newParamsKzFromP] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand);
sceneResults.metricsPostKzFromP = OnlineCalibration.aux.runGeometricMetrics(frameCB, newParamsKzFromP);
cbVerticesKz = [xcb,ycb,ones(size(xcb))]*inv(newParamsKzFromP.Kdepth)'.*cbVertices(:,3);
sceneResults.uvErrPostKzFromPOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKzFromP,0,cbVerticesKz');
[sceneResults.gidPostKzFromP,sceneResults.scaleErrorHPostKzFromP,sceneResults.scaleErrorVPostKzFromP] = OnlineCalibration.Metrics.gidAndScaleFromVerts(cbVerticesKz,30,[20,28]);



while ~converged && iterNum < params.maxK2DSMIters
    % K2DSM
    [currentFrameCand,newParamsK2DSMCand,acDataCand,dsmRegsCand] = OnlineCalibration.K2DSM.convertNewK2DSM(currentFrame,newParamsKzFromP,acData,dsmRegs,regs,params);
    % Optimize P
    [newCostCand,newParamsPCand,newParamsKzFromPCand] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand);
    if newCostCand < lastCost
        % End iterations
        converged = 1;
    else
        iterNum = iterNum + 1;
        
        
        % Update CB vertices
        [cbVertices,~,~] = OnlineCalibration.K2DSM.updateVerticesWithNewDSM(cbVertices,regs,dsmRegs,dsmRegsCand,params.Kdepth);

        
        sceneResults.uvErrPostK2DSM(iterNum) = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsK2DSMCand,0,cbVertices');
        [sceneResults.gidPostK2DSM(iterNum),sceneResults.scaleErrorHPostK2DSM(iterNum),sceneResults.scaleErrorVPostK2DSM(iterNum)] = OnlineCalibration.Metrics.gidAndScaleFromVerts(cbVertices,30,[20,28]);

        
        currentFrame = currentFrameCand;
        lastCost = newCostCand;
        sceneResults.newCost(iterNum) = newCostCand;
        newParamsP = newParamsPCand;
        newParamsKzFromP = newParamsKzFromPCand;
        newParamsK2DSM = newParamsK2DSMCand;
        acData = acDataCand;
        dsmRegs = dsmRegsCand;
        
        
    end
    
end


sceneResults.acDataOutPreClipping = acData;
acData = OnlineCalibration.K2DSM.clipACScaling(acData,sceneResults.acDataIn,params.maxGlobalLosScalingStep);

sceneResults.numberOfIteration = iterNum;
[finalParams,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsP,newParamsK2DSM,originalParams,params.iterFromStart);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct); 
decisionParams.newCost = sceneResults.newCost(end);
sceneResults.desicionParams = decisionParams;
sceneResults.acDataOut = acData;
sceneResults.newParamsK2DSM = newParamsK2DSM;
sceneResults.finalParams = finalParams;
[sceneResults.validFixBySVM,sceneResults.svmDebug] = OnlineCalibration.aux.validBySVM(sceneResults.desicionParams,newParamsP);
sceneResults.validMovement = ~isMovement && isMovementFromLastSuccess;
sceneResults.validMovementFromOrigin = validOutputStruct.xyMovementFromOrigin <= params.maxXYMovementFromOrigin;

sceneResults.codeOutBin = OnlineCalibration.aux.outputErrorCode(decisionParams,validOutputStruct,params);
if ~sceneResults.validFixBySVM || ~sceneResults.validMovement || ~sceneResults.validMovementFromOrigin
    OnlineCalibration.aux.recordConvergData2Log(decisionParams,validOutputStruct,params,sceneDir);
end
end