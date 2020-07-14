function [sceneResults] = runIterativeAC2FromDir(sceneDir,params)
global runParams;
runParams.loadSingleScene = 1;
sceneResults = struct;
sceneResults.sceneFullPath = fullfile(sceneDir,'Scene');
sceneResults.cbFullPath = fullfile(sceneDir,'CheckerBoard');
if contains(sceneDir,'aged')
    load(fullfile(sceneResults.sceneFullPath,'cameraParams.mat'),'cameraParams');
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
frameCB.z = frameCB.z(:,:,end);
frameCB.i = frameCB.i(:,:,end);
frameCB.yuy2Prev = frameCB.yuy2(:,:,end-1);
frameCB.yuy2 = frameCB.yuy2(:,:,end);
if isfield(params,'runOnCB') && params.runOnCB
    currentFrame = frameCB;
else
    currentFrame.yuy2Prev = frame.yuy2(:,:,1);
    currentFrame.z = frame.z(:,:,end);
    currentFrame.i = frame.i(:,:,end);
    currentFrame.yuy2 = frame.yuy2(:,:,2);
end
currentFrame.yuy2FromLastSuccess = zeros(size(currentFrame.yuy2));



[sceneResults.uvErrPreWithoutAug] = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,params,0);
[sceneResults.metricsPreWithoutAug] = OnlineCalibration.aux.runGeometricMetrics(frameCB, params);
 
[currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(currentFrame,params,params.augMethod);
[frameCB,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(frameCB,params,params.augMethod);
originalParams = params;
sceneResults.originalParams = originalParams;


calData = Calibration.tables.getCalibDataFromCalPath(params.atcPath, params.accPath);
regsDEST.hbaseline = 0;
regsDEST.baseline = -10;
regsDEST.baseline2 = regsDEST.baseline^2;
regs = calData.regs;
regs.DEST = mergestruct(regs.DEST, regsDEST);
dsmRegsOrig = calData.regs.EXTL;
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