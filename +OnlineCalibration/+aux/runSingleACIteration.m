function [validParams,params,newAcDataTable,newAcDataStruct,sceneResults] = runSingleACIteration(currentFrame,params,originalParams,dataForACTableGeneration)
% dataForACTableGeneration - A struct with the fields: DSMRegs,
% calibTableBin, acTableBin
sceneResults.params = params;


%% Prepare input params for AC
if iscell(dataForACTableGeneration.acDataBin) % got from python interface
   dataForACTableGeneration.acDataBin = cell2mat(dataForACTableGeneration.acDataBin); 
   dataForACTableGeneration.calibDataBin = cell2mat(dataForACTableGeneration.calibDataBin); 
end
if dataForACTableGeneration.binWithHeaders
   headerSize = 16;
   dataForACTableGeneration.acDataBin = dataForACTableGeneration.acDataBin(headerSize+1:end);
   dataForACTableGeneration.calibDataBin = dataForACTableGeneration.calibDataBin(headerSize+1:end);
end
acData = Calibration.tables.convertBinTableToCalibData(uint8(dataForACTableGeneration.acDataBin), 'Algo_AutoCalibration');
acData.flags = mod(acData.flags(1),2);
regs = Calibration.tables.convertBinTableToCalibData(uint8(dataForACTableGeneration.calibDataBin), 'Algo_Calibration_Info_CalibInfo');
dsmRegs.dsmXscale = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmXscale),'single');
dsmRegs.dsmXoffset = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmXoffset),'single');
dsmRegs.dsmYscale = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmYscale),'single');
dsmRegs.dsmYoffset = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmYoffset),'single');
regs.FRMW.rtdOverX(1:6) = 0;
regs.FRMW.rtdOverY(1:3) = 0;
regs.FRMW.mirrorMovmentMode = 1;
regs.DEST.baseline2 = regs.DEST.baseline^2;
KRaw = OnlineCalibration.aux.rotateKMat(params.Kdepth,params.depthRes);
sceneResults.acDataIn = acData;


% Preprocess RGB
[currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);

[currentFrame.irEdge,currentFrame.zEdge,...
    currentFrame.xim,currentFrame.yim,currentFrame.zValuesForSubEdges...
    ,currentFrame.zGradInDirection,currentFrame.dirPerPixel,currentFrame.weights,currentFrame.vertices,...
    currentFrame.sectionMapDepth,currentFrame.relevantPixelsImage] = OnlineCalibration.aux.preprocessDepth(currentFrame,params);


currentFrame.originalVertices = currentFrame.vertices;
[~,decisionParams,isMovement] = OnlineCalibration.aux.validScene(currentFrame,params);

%% Perform Optimization
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(currentFrame.vertices,currentFrame.weights,currentFrame.rgbIDT,params);

%% Set initial value for some variables that change between iterations
currentFrameCand = currentFrame;
newParamsK2DSM = params;
converged = false;
iterNum = 1;
lastCost = decisionParams.initialCost;
dsmRegsCand = dsmRegs;
acDataCand = acData;



while ~converged && iterNum < params.maxK2DSMIters
    [newCostCand,newParamsPCand,newParamsKzFromPCand] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSM);
    if newCostCand < lastCost
        converged = 1;
        continue;
    end
    currentFrame = currentFrameCand;
    lastCost = newCostCand;
    sceneResults.newCost(iterNum) = newCostCand;
    newParamsP = newParamsPCand;
    newParamsKzFromP = newParamsKzFromPCand;
    acData = acDataCand;
    dsmRegs = dsmRegsCand;
    % K2DSM
    newKdepth = newParamsKzFromP.Kdepth;
    newParamsK2DSM = newParamsKzFromP;
    newParamsK2DSM.Kdepth = params.Kdepth;
    
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

    % Optimize
    iterNum = iterNum + 1;
end



sceneResults.numberOfIteration = iterNum - 1;
[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsP,originalParams,params.iterFromStart);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct); 
decisionParams.newCost = sceneResults.newCost(end);
sceneResults.desicionParams = decisionParams;

sceneResults.validFixBySVM = OnlineCalibration.aux.validBySVM(sceneResults.desicionParams,newParamsK2DSM);
sceneResults.validMovement = ~isMovement;
sceneResults.acDataOut = acData;



acData.flags(2:6) = uint8(0);
newAcDataTable = Calibration.tables.convertCalibDataToBinTable(acData, 'Algo_AutoCalibration');
newAcDataStruct = acData;

validParams = sceneResults.validMovement && sceneResults.validFixBySVM;

if iterNum > 2 % Else params remain the same and acdataIn is equal to ACDataout
    params = newParamsK2DSM;
end


end