function [validParams,params,newAcDataTable,newAcDataStruct,sceneResults] = runSingleACIteration(currentFrame,params,originalParams,dataForACTableGeneration)
% dataForACTableGeneration - A struct with the fields: DSMRegs,
% calibTableBin, acTableBin
sceneResults.params = params;
if ~isfield(currentFrame,'lastValidYuy2')
    currentFrame.lastValidYuy2 = 0*currentFrame.yuy2;
end

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
sceneResults.validAcAndDsmInputs = OnlineCalibration.aux.checkInputParameters(dsmRegs,acData,params);


% Preprocess RGB
[currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy,currentFrame.sectionMapRgb,currentFrame.sectionMapRgbEdges] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);


[currentFrame.irEdge,currentFrame.zEdge,...
    currentFrame.xim,currentFrame.yim,currentFrame.zValuesForSubEdges...
    ,currentFrame.zGradInDirection,currentFrame.dirPerPixel,currentFrame.weights,currentFrame.vertices,...
    currentFrame.sectionMapDepth,currentFrame.relevantPixelsImage] = OnlineCalibration.aux.preprocessDepth(currentFrame,params);

%% Update oriignal acTable,vertices, xim and yim if a new acData is in params
if isfield(params,'acData')  && ~isempty(params.acData) && ~isempty(currentFrame.vertices) && sceneResults.validAcAndDsmInputs % Simulate the new AC data as a starting point
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse');
    dsmRegsNew = Utils.convert.applyAcResOnDsmModel(params.acData, dsmRegsOrig, 'direct');
    [currentFrame.vertices,currentFrame.xim,currentFrame.yim] = OnlineCalibration.K2DSM.updateVerticesWithNewDSM(currentFrame.vertices,regs,dsmRegs,dsmRegsNew,params.Kdepth);
    dsmRegs = dsmRegsNew;
    acData = params.acData;
end
sceneResults.acDataIn = acData;
sceneResults.acDataOut = acData;
sceneResults.acDataOutPreClipping = acData;
if isempty(currentFrame.vertices) || ~sceneResults.validAcAndDsmInputs
    validParams = 0;
    newAcDataTable = [];
    newAcDataStruct = acData;
    return;
end



currentFrame.originalVertices = currentFrame.vertices;
[~,decisionParams,isMovement] = OnlineCalibration.aux.validScene(currentFrame,params);
[sceneResults.validInputs,directionData,sceneResults.inputValidityDbg] = OnlineCalibration.aux.inputValidityChecks(currentFrame,params);
if params.normalizeWeightsPerDir
    currentFrame.weights = OnlineCalibration.aux.normalizeWeigthtsPerDirection(currentFrame.weights,currentFrame.dirPerPixel,directionData.validDirections,directionData.edgesPerDirection);
end
%% Calculate initial cost
[decisionParams.initialCost] = OnlineCalibration.aux.calculateCost(currentFrame.vertices,currentFrame.weights,currentFrame.rgbIDT,params);
originalFrame = currentFrame;
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
        % No change at all (probably very good starting point)
        if iterNum == 0 
            newParamsK2DSM = params;
            newParamsP = params;
            sceneResults.newCost = lastCost;
        end
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

% Clip scaling factors
sceneResults.acDataOutPreClipping = acData;
[acData, sceneResults.performedClipping]  = OnlineCalibration.K2DSM.clipACScaling(acData,sceneResults.acDataIn,params.maxGlobalLosScalingStep);

%% Validate new parameters
[finalParams,dbg,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParamsP,newParamsK2DSM,originalParams,params.iterFromStart);
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

validParams = sceneResults.validInputs && sceneResults.validMovement && sceneResults.validFixBySVM && (iterNum >= 1);
newAcDataStruct = acData;

if iterNum >= 1  % Else params remain the same and acdataIn is equal to ACDataout
    params = finalParams;
end

if isfield(params,'outputFolder')   
   %% IR & Z figure
   ff = Calibration.aux.invisibleFigure; 
   subplot(121);
   imagesc(currentFrame.i);colorbar;
   hold on;
   plot(originalFrame.xim+1,originalFrame.yim+1,'r*','markersize',1);
   title('IR');
   subplot(122);
   imagesc(currentFrame.z/params.zMaxSubMM);colorbar;
   hold on;
   plot(originalFrame.xim+1,originalFrame.yim+1,'r*','markersize',1);
   title('Z');
   Calibration.aux.saveFigureAsImage(ff,params,'IRandZ','',1,0,0);
   Calibration.aux.saveFigureAsImage(ff,params,'IRandZ','',1,1,0);
   %% IR & Z Edge figure
%    ff = Calibration.aux.invisibleFigure; 
%    subplot(121);
%    imagesc(currentFrame.irEdge);colorbar;
%    hold on;
%    plot(originalFrame.xim+1,originalFrame.yim+1,'r*','markersize',1);
%    title('IR Edge');
%    subplot(122);
%    imagesc(currentFrame.zEdge);colorbar;
%    hold on;
%    plot(originalFrame.xim+1,originalFrame.yim+1,'r*','markersize',1);
%    title('Z Edge');
%    Calibration.aux.saveFigureAsImage(ff,params,'IRandZEdge','',1);

   % Initial and final uv mappin
   ff = Calibration.aux.invisibleFigure; 
   imagesc(currentFrame.yuy2);
   hold on
   plot(dbg.uvMapOrig(:,1)+1,dbg.uvMapOrig(:,2)+1,'r*','markersize',1);
   plot(dbg.uvMapNew(:,1)+1,dbg.uvMapNew(:,2)+1,'g*','markersize',1);
   title('YUY2');
   legend({'UVPre';'UVPost'});
   Calibration.aux.saveFigureAsImage(ff,params,'UVInitAndFinal','',1,0,0);
   Calibration.aux.saveFigureAsImage(ff,params,'UVInitAndFinal','',1,1,0);
   
%    % Initial and final uv mappin
%    ff = Calibration.aux.invisibleFigure; 
%    imagesc(currentFrame.rgbIDT);
%    hold on
%    plot(dbg.uvMapOrig(:,1)+1,dbg.uvMapOrig(:,2)+1,'r*','markersize',1);
%    plot(dbg.uvMapNew(:,1)+1,dbg.uvMapNew(:,2)+1,'g*','markersize',1);
%    title('Inverse Distance Transform');
%    legend({'UVPre';'UVPost(Pre Los Scale Clipping)'});
%    Calibration.aux.saveFigureAsImage(ff,params,'IDT_UVInitAndFinal','',1,0,0);
%    Calibration.aux.saveFigureAsImage(ff,params,'IDT_UVInitAndFinal','',1,1,0);

   % Isvalid, cost improvement
   
end
end