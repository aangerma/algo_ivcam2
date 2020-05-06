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


newParamsKzFromP = newParamsP;
newParamsKzFromP.derivVar = 'Kdepth';
[newParamsKzFromP.Krgb,newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsKzFromP.rgbPmat);
newParamsKzFromP.Krgb(1,2) = 0;
newParamsKzFromP.Kdepth([1,5]) = newParamsKzFromP.Kdepth([1,5])./newParamsKzFromP.Krgb([1,5]).*params.Krgb([1,5]);
newParamsKzFromP.Krgb([1,5]) = originalParams.Krgb([1,5]);
newParamsKzFromP.rgbPmat = newParamsKzFromP.Krgb*[newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb];
[newParamsKzFromP.xAlpha,newParamsKzFromP.yBeta,newParamsKzFromP.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(newParamsKzFromP.Rrgb);


[~,~,~,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(frame,params,newParamsKzFromP,originalParams,params.iterFromStart);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct);


sceneResults.newParamsKzFromP = newParamsKzFromP;
sceneResults.decisionParamsKzFromP = decisionParams;
sceneResults.validFixBySVM = OnlineCalibration.aux.validBySVM(sceneResults.decisionParamsKzFromP,newParamsKzFromP);
sceneResults.validMovement = ~isMovement;

validParams = sceneResults.validMovement && sceneResults.validFixBySVM;

if validParams
    params = newParamsKzFromP;
end

end