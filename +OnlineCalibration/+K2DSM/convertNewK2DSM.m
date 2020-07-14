function [currentFrameCand,newParamsK2DSM,acDataCand,dsmRegsCand,dsmData,inputs] = convertNewK2DSM(currentFrame,newParamsKzFromP,acData,dsmRegs,regs,params)
% This function converts the new K depth to a dsm fix via new AC table
    [inputs] = createInputDebugStruct(newParamsKzFromP,acData,dsmRegs,params,currentFrame.vertices);

    newKdepth = newParamsKzFromP.Kdepth;
    newParamsK2DSM = newParamsKzFromP;
    newParamsK2DSM.Kdepth = params.Kdepth;
    newKRaw = OnlineCalibration.aux.rotateKMat(newKdepth,params.depthRes);
    KRaw = OnlineCalibration.aux.rotateKMat(params.Kdepth,params.depthRes);
    
    [acData] = setStructFields2Double(acData,{'hFactor';'vFactor';'hOffset';'vOffset'});
    [dsmRegs] = setStructFields2Double(dsmRegs);
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse');
    
    [preProcData, first_ConvertNormVerticesToLos_data] = OnlineCalibration.K2DSM.PreProcessing(regs, acData, dsmRegs, KRaw, rot90(currentFrame.relevantPixelsImage,2), params.maxLosScalingStep);
    losShift = zeros(2,1); % any residual LOS shift is reflected onto RGB principle point and/or extrinsic translation
    [losScaling,dbgK2LosErr] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, newKRaw);
    acDataCand = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acData, acData.flags(1), losShift, losScaling);
    dsmRegsCand = Utils.convert.applyAcResOnDsmModel(acDataCand, dsmRegsOrig, 'direct');
%         acDataInCand.flags(2:6) = uint8(0);
    % Apply the new scaling to xim and yim for next iteration
    % Transforming pixels to LOS
    scVertices = currentFrame.vertices;
    scVertices(:,1:2) = -scVertices(:,1:2);
    [los,second_ConvertNormVerticesToLos_data] = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegs, scVertices);
    [newVertices, dsmX,dsmY]  = OnlineCalibration.K2DSM.ConvertLosToNormVertices(regs, dsmRegsCand, los);
    [dsmData] = createDsmDataStruct(dsmRegsOrig,dbgK2LosErr,first_ConvertNormVerticesToLos_data,second_ConvertNormVerticesToLos_data,preProcData,currentFrame.relevantPixelsImage,losScaling,los,dsmX,dsmY);
    newVertices = newVertices./newVertices(:,3).*scVertices(:,3);
    newVertices(:,1:2) = -newVertices(:,1:2);
    projed = newVertices*params.Kdepth';
    ximNew = projed(:,1)./projed(:,3);
    yimNew = projed(:,2)./projed(:,3);
    
    currentFrameCand = currentFrame;
    currentFrameCand.xim = ximNew;
    currentFrameCand.yim = yimNew;
    currentFrameCand.vertices = newVertices;

 

end

function [inputs] = createInputDebugStruct(newParamsKzFromP,acData,dsmRegs,params,vertices)
inputs.newKdepth = newParamsKzFromP.Kdepth;
inputs.oldKdepth = params.Kdepth;
inputs.vertices = vertices;
inputs.acData = acData;
inputs.dsmRegs = dsmRegs;
end

function [structOut] = setStructFields2Double(structIn,structFieldNamesIn)
if exist('structFieldNamesIn','var')
    structFieldNames = structFieldNamesIn;
else
    structFieldNames = fieldnames(structIn);
end
structOut = structIn;
for k = 1:numel(structFieldNames)
    structOut.(structFieldNames{k}) = double(structIn.(structFieldNames{k}));
end
end

function [dsmData] = createDsmDataStruct(dsmRegsOrig,dbgK2LosErr,first_ConvertNormVerticesToLos_data,second_ConvertNormVerticesToLos_data,preProcData,relevantPixelsImage,losScaling,los,dsmX,dsmY)
dsmData.dsmRegsOrig = dsmRegsOrig;
dsmData.preProcData = preProcData;
dsmData.preProcData.relevantPixelnImage_rot = rot90(relevantPixelsImage,2);
dsmData.focalScaling = dbgK2LosErr.focalScaling;
dsmData.errL2 = dbgK2LosErr.errL2;
dsmData.sg_mat_tag_x_sg_mat = dbgK2LosErr.sg_mat_tag_x_sg_mat;
dsmData.sg_mat_tag_x_err_l2 = dbgK2LosErr.sg_mat_tag_x_err_l2;
dsmData.quadCoef = dbgK2LosErr.quadCoef;
dsmData.sgMat = dbgK2LosErr.sgMat;
dsmData.optScaling1 = dbgK2LosErr.optScaling1;
dsmData.optScaling = dbgK2LosErr.optScaling;
dsmData.newlosScaling = losScaling;
dsmData.first_ConvertNormVerticesToLos_data = first_ConvertNormVerticesToLos_data;
dsmData.second_ConvertNormVerticesToLos_data = second_ConvertNormVerticesToLos_data;
dsmData.orig_los = los;
dsmData.dsm = [ dsmX dsmY];
end