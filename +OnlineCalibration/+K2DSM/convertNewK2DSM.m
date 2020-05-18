function [currentFrameCand,newParamsK2DSM,acDataCand,dsmRegsCand] = convertNewK2DSM(currentFrame,newParamsKzFromP,acData,dsmRegs,regs,params)
% This function converts the new K depth to a dsm fix via new AC table
    newKdepth = newParamsKzFromP.Kdepth;
    newParamsK2DSM = newParamsKzFromP;
    newParamsK2DSM.Kdepth = params.Kdepth;
    newKRaw = OnlineCalibration.aux.rotateKMat(newKdepth,params.depthRes);
    KRaw = OnlineCalibration.aux.rotateKMat(params.Kdepth,params.depthRes);
    
    
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

 

end
