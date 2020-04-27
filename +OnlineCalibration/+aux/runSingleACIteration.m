function [validParams,params,sceneResults] = runSingleACIteration(frame,params,originalParams)
sceneResults.params = params;

% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);

[frame.irEdge,frame.zEdge,...
    frame.xim,frame.yim,frame.zValuesForSubEdges...
    ,frame.zGradInDirection,frame.dirPerPixel,frame.weights,frame.vertices,...
    frame.sectionMapDepth] = OnlineCalibration.aux.preprocessDepth(frame,params);


frame.originalVertices = frame.vertices;
[~,decisionParams,isMovement] = OnlineCalibration.aux.validScene(frame,params);

%% Perform Optimization
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);

params.derivVar = 'P';
[newParamsP,decisionParams.newCost] = OnlineCalibration.Opt.optimizeParametersP(frame,params);

newParamsPDecomposed = newParamsP;
newParamsPDecomposed.derivVar = 'PDecomposed';
[newParamsPDecomposed.Krgb,newParamsPDecomposed.Rrgb,newParamsPDecomposed.Trgb] = OnlineCalibration.aux.decompose_projmtx(newParamsPDecomposed.rgbPmat);
newParamsPDecomposed.Krgb(1,2) = 0;
newParamsPDecomposed.rgbPmat = newParamsPDecomposed.Krgb*[newParamsPDecomposed.Rrgb,newParamsPDecomposed.Trgb];
[newParamsPDecomposed.xAlpha,newParamsPDecomposed.yBeta,newParamsPDecomposed.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(newParamsPDecomposed.Rrgb);

[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(frame,params,newParamsPDecomposed,originalParams,params.iterFromStart);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct);


sceneResults.newParamsPDecomposed = newParamsPDecomposed;
sceneResults.decisionParamsPDecomposed = decisionParams;
sceneResults.validFixBySVM = OnlineCalibration.aux.validBySVM(sceneResults.decisionParamsPDecomposed,newParamsPDecomposed);
sceneResults.validMovement = ~isMovement;

validParams = sceneResults.validMovement && sceneResults.validFixBySVM;

end