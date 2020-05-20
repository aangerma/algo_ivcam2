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

%% Calculate initial cost
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(currentFrame.vertices,currentFrame.weights,currentFrame.rgbIDT,params);

%% Set initial value for some variables that change between iterations
currentFrameCand = currentFrame;
newParamsK2DSMCand = params;
converged = false;
iterNum = 0;
lastCost = decisionParams.initialCost;

[~,~,newParamsKzFromP] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand);
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

sceneResults.numberOfIteration = iterNum;


%% Validate new parameters
[finalParams,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsP,newParamsK2DSM,originalParams,params.iterFromStart);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct); 
decisionParams.newCost = sceneResults.newCost(end);
sceneResults.decisionParams = decisionParams;

sceneResults.validFixBySVM = OnlineCalibration.aux.validBySVM(sceneResults.decisionParams,finalParams);
sceneResults.validMovement = ~isMovement;
sceneResults.acDataOut = acData;
sceneResults.newParamsK2DSM = newParamsK2DSM;
sceneResults.finalParams = finalParams;


acData.flags(2:6) = uint8(0);
newAcDataTable = Calibration.tables.convertCalibDataToBinTable(acData, 'Algo_AutoCalibration');
newAcDataStruct = acData;

validParams = sceneResults.validMovement && sceneResults.validFixBySVM;

if iterNum >= 1 % Else params remain the same and acdataIn is equal to ACDataout
    params = newParamsK2DSM;% Should be final params
end


end