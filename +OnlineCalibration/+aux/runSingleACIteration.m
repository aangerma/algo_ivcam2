function [validParams,params,newAcDataTable,newAcDataStruct,sceneResults] = runSingleACIteration(frame,params,originalParams,dataForACTableGeneration)
% dataForACTableGeneration - A struct with the fields: DSMRegs,
% calibTableBin, acTableBin
newAcDataTable = [];
newAcDataStruct = [];
sceneResults.params = params;
sceneResults.newAcDataStruct = struct;
sceneResults.losShift = [];
sceneResults.losScaling = [];
% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);

[frame.irEdge,frame.zEdge,...
    frame.xim,frame.yim,frame.zValuesForSubEdges...
    ,frame.zGradInDirection,frame.dirPerPixel,frame.weights,frame.vertices,...
    frame.sectionMapDepth,frame.relevantPixelsImage] = OnlineCalibration.aux.preprocessDepth(frame,params);


frame.originalVertices = frame.vertices;
[~,decisionParams,isMovement] = OnlineCalibration.aux.validScene(frame,params);

%% Perform Optimization
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);

params.derivVar = 'P';
[newParamsP,decisionParams.newCost] = OnlineCalibration.Opt.optimizeParametersP(frame,params);


newParamsKzFromP = newParamsP;
newParamsKzFromP.derivVar = 'Kdepth';
[newParamsKzFromP.Krgb,newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsKzFromP.rgbPmat);
newParamsKzFromP.Krgb(1,2) = 0;
newParamsKzFromP.Kdepth([1,5]) = newParamsKzFromP.Kdepth([1,5])./newParamsKzFromP.Krgb([1,5]).*params.Krgb([1,5]);
newParamsKzFromP.Krgb([1,5]) = originalParams.Krgb([1,5]);
newParamsKzFromP.rgbPmat = newParamsKzFromP.Krgb*[newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb];
[newParamsKzFromP.xAlpha,newParamsKzFromP.yBeta,newParamsKzFromP.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(newParamsKzFromP.Rrgb);


[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(frame,params,newParamsP,originalParams,params.iterFromStart);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct);


sceneResults.newParamsKzFromP = newParamsKzFromP;
sceneResults.decisionParamsKzFromP = decisionParams;
sceneResults.validFixBySVM = OnlineCalibration.aux.validBySVM(sceneResults.decisionParamsKzFromP,newParamsKzFromP);
sceneResults.validMovement = ~isMovement;

validParams = sceneResults.validMovement && sceneResults.validFixBySVM;

if validParams || (isfield(params,'ignoreValidity') && params.ignoreValidity)
    % Take the resulting params, keep the original kdepth as 
    newKdepth = newParamsKzFromP.Kdepth;
    newParamsKzFromP.Kdepth = params.Kdepth;
    params = newParamsKzFromP;
    
    if iscell(dataForACTableGeneration.acDataBin) % got from python interface
       dataForACTableGeneration.acDataBin = cell2mat(dataForACTableGeneration.acDataBin); 
       dataForACTableGeneration.calibDataBin = cell2mat(dataForACTableGeneration.calibDataBin); 
    end
    if dataForACTableGeneration.binWithHeaders
       headerSize = 16;
       dataForACTableGeneration.acDataBin = dataForACTableGeneration.acDataBin(headerSize+1:end);
       dataForACTableGeneration.calibDataBin = dataForACTableGeneration.calibDataBin(headerSize+1:end);
    end

    [newAcDataTable,newAcDataStruct,losShift, losScaling] = OnlineCalibration.K2DSM.AC2ResultsToDSM(dataForACTableGeneration,params,newKdepth,frame.relevantPixelsImage);
    
    sceneResults.newAcDataStruct = newAcDataStruct;
    sceneResults.losShift = losShift;
    sceneResults.losScaling = losScaling;
    
end

end