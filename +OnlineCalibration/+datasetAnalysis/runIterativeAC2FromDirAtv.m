function [sceneResults] = runIterativeAC2FromDirAtv(sceneDir,params)
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
[params] = OnlineCalibration.aux.getCameraParamsFromAtvRun(sceneResults.atvDataPath,params);
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);
[params] = OnlineCalibration.datasetAnalysis.getAugmentationParams(params);
params.targetType = 'checkerboard_Iv2A1';
params.serial = strsplit(sceneDir,'\'); params.serial = params.serial{end-2};
[params.atcPath,params.accPath,params.calPathValid] = OnlineCalibration.aux.serialToCalDirs(params.serial);

currentFrame.yuy2Prev = frame.yuy2;
currentFrame.z = frame.z;
currentFrame.i = frame.i;
currentFrame.yuy2 = frame.yuy2;



[sceneResults.uvErrPreWithoutAug] = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,params,0);
[sceneResults.metricsPreWithoutAug] = OnlineCalibration.aux.runGeometricMetrics(frameCB, params);
 
[currentFrame,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(currentFrame,params,params.augMethod);
[frameCB,params] = OnlineCalibration.datasetAnalysis.augmentFrameAndParams(frameCB,params,params.augMethod);
originalParams = params;
sceneResults.originalParams = originalParams;

acData = OnlineCalibration.aux.defaultACTable();
acData.flags = 1;
calData = Calibration.tables.getCalibDataFromCalPath(params.atcPath, params.accPath);
regsDEST.hbaseline = 0;
regsDEST.baseline = -10;
regsDEST.baseline2 = regsDEST.baseline^2;
regs = calData.regs;
regs.DEST = mergestruct(regs.DEST, regsDEST);
dsmRegs = calData.regs.EXTL;


[sceneResults.uvErrPre,cbVertices] = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,originalParams,0);
[sceneResults.metricsPre] = OnlineCalibration.aux.runGeometricMetrics(frameCB, originalParams);
[sceneResults.gidPre,sceneResults.scaleErrorHPre,sceneResults.scaleErrorVPre] = gidFromVerts(cbVertices,30,[20,28]);
currentFrame = OnlineCalibration.aux.preprocess(currentFrame,params);
currentFrameCand = currentFrame;
newParamsK2DSM = params;
converged = false;
iterNum = 0;
% Calculate input validity params cost
[~,decisionParams,isMovement] = OnlineCalibration.aux.validScene(currentFrameCand,params);
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(currentFrameCand.vertices,currentFrameCand.weights,currentFrameCand.rgbIDT,params);
lastCost = decisionParams.initialCost;
dsmRegsCand = dsmRegs;
acDataCand = acData;

if params.rgbThermalFix
    params.thermalInputParams.fromFile = 1;
    params.thermalInputParams.tablePath = OnlineCalibration.aux.getRgbThermalTablePathAc(sceneDir);
end
while ~converged && iterNum < params.maxK2DSMIters
    [newCostCand,newParamsPCand,newParamsKzFromPCand] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSM);
    if newCostCand < lastCost
        converged = 1;
        continue;
    end
    currentFrame = currentFrameCand;
    lastCost = newCostCand;
    sceneResults.newCost(iterNum+1) = newCostCand;
    newParamsP = newParamsPCand;
    newParamsKzFromP = newParamsKzFromPCand;
    acData = acDataCand;
    dsmRegs = dsmRegsCand;
    % Calc metrics pre K2DSM
    if iterNum == 0
        sceneResults.metricsPostKzFromP = OnlineCalibration.aux.runGeometricMetrics(frameCB, newParamsKzFromP);
        sceneResults.uvErrPostKzFromPOpt = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsKzFromP,0);
    end
    % K2DSM
    newKdepth = newParamsKzFromP.Kdepth;
    newParamsK2DSM = newParamsKzFromP;
    newParamsK2DSM.Kdepth = params.Kdepth;
    
    KRaw = OnlineCalibration.aux.rotateKMat(params.Kdepth,params.depthRes);
    newKRaw = OnlineCalibration.aux.rotateKMat(newKdepth,params.depthRes);
    
    
    
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse');
    preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acData, dsmRegs, params.depthRes, KRaw, rot90(currentFrame.relevantPixelsImage,2));
    [losShift, losScaling] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, newKRaw);
    acDataCand = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acData, acData.flags, losShift, losScaling);
    dsmRegsCand = Utils.convert.applyAcResOnDsmModel(acDataCand, dsmRegsOrig, 'direct');
%         acDataInCand.flags(2:6) = uint8(0);
    % Apply the new scaling to xim and yim for next iteration
    % Transforming pixels to LOS
    scVertices = currentFrame.vertices;
    scVertices(:,1:2) = -scVertices(:,1:2);
    los = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegs, scVertices);
    newVertices = OnlineCalibration.K2DSM.ConvertLosToNormVertices(regs, dsmRegsCand, los);
    newVertices = newVertices./newVertices(:,3).*scVertices(:,3);
    newVertices(:,1:2) = -newVertices(:,1:2);
    projed = newVertices*params.Kdepth';
    ximNew = projed(:,1)./projed(:,3);
    yimNew = projed(:,2)./projed(:,3);
    
    currentFrameCand = currentFrame;
    currentFrameCand.xim = ximNew;
    currentFrameCand.yim = yimNew;
    currentFrameCand.vertices = newVertices;

    zValsCB = cbVertices(:,3);
    cbVertices(:,1:2) = -cbVertices(:,1:2);
    los = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegs, cbVertices);
    cbVertices = OnlineCalibration.K2DSM.ConvertLosToNormVertices(regs, dsmRegsCand, los);
    cbVertices = cbVertices./cbVertices(:,3).*zValsCB;
    cbVertices(:,1:2) = -cbVertices(:,1:2);
    sceneResults.uvErrPostK2DSM(iterNum+1) = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,newParamsK2DSM,0,cbVertices');
    [sceneResults.gidPostK2DSM(iterNum+1),sceneResults.scaleErrorHPostK2DSM(iterNum+1),sceneResults.scaleErrorVPostK2DSM(iterNum+1)] = gidFromVerts(cbVertices,30,[20,28]);
    
    % Optimize
    iterNum = iterNum + 1;
end

sceneResults.numberOfIteration = iterNum;
[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsP,originalParams,1);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct); 
decisionParams.newCost = sceneResults.newCost(end);
sceneResults.desicionParams = decisionParams;

[sceneResults.validFixBySVM,sceneResults.features] = OnlineCalibration.aux.validBySVM(sceneResults.desicionParams,newParamsP);
sceneResults.validMovement = ~isMovement;


    


end

function [gid,scaleErrorH,scaleErrorV] = gidFromVerts(gridVertices,squareSize,gridSize)
n = size(gridVertices, 1);
[sy, sx] = ndgrid((1:gridSize(1))*squareSize, (1:gridSize(2))*squareSize);% ideal corner grid
[iy, ix] = ndgrid(1:n, 1:n);
X = ix(:);
Y = iy(:);
% gridVertices should be the matrix %
dbg.dv = sqrt((gridVertices(X,1)-gridVertices(Y,1)).^2 + (gridVertices(X,2)-gridVertices(Y,2)).^2 + (gridVertices(X,3)-gridVertices(Y,3)).^2);% Distance from each corner vertices  to the other
dbg.ds = sqrt((sx(X)-sx(Y)).^2 + (sy(X)-sy(Y)).^2);% Distance from each ideal corner to the other
dbg.scaleErrors = dbg.dv-dbg.ds; % differance between detected vertices distance to the ideal 
gid = nanmean(abs(dbg.scaleErrors)); 



% scale error
v = gridVertices;
gridIndexMat = reshape(1:n, gridSize);
Xright = gridIndexMat(:,2:end);
Xleft = gridIndexMat(:,1:end-1);
% horizontal distance between corners is compared to the known squareSize
dvHorz = sqrt((v(Xright,1)-v(Xleft,1)).^2 + (v(Xright,2)-v(Xleft,2)).^2 + (v(Xright,3)-v(Xleft,3)).^2);
horzScaleError = (dvHorz-squareSize)/squareSize;
scaleErrorH = nanmean(abs(horzScaleError));

Xtop = gridIndexMat(1:end-1,:);
Xbottom = gridIndexMat(2:end,:);
% Vertical distance between corners is compared to the known squareSize
dvVert = sqrt((v(Xtop,1)-v(Xbottom,1)).^2 + (v(Xtop,2)-v(Xbottom,2)).^2 + (v(Xtop,3)-v(Xbottom,3)).^2);
vertScaleError = (dvVert-squareSize)/squareSize;
scaleErrorV = nanmean(abs(vertScaleError));
end