function [currentFrameCand,newParamsK2DSM,acDataCand,dsmRegsCand, dsmData] = convertNewK2DSM(currentFrame,newParamsKzFromP,acData,dsmRegs,regs,params,cycle)
% This function converts the new K depth to a dsm fix via new AC table
    newKdepth = newParamsKzFromP.Kdepth;
    newParamsK2DSM = newParamsKzFromP;
    newParamsK2DSM.Kdepth = params.Kdepth;
    newKRaw = OnlineCalibration.aux.rotateKMat(newKdepth,params.depthRes);
    KRaw = OnlineCalibration.aux.rotateKMat(params.Kdepth,params.depthRes);
    
    acData.hFactor = double( acData.hFactor);
    acData.vFactor = double( acData.vFactor);
    acData.hOffset = double( acData.hOffset);
    acData.vOffset = double( acData.vOffset);
    
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse');
    dsmData.dsmRegsOrig = dsmRegsOrig;
    dsmRegs.dsmXscale = double(dsmRegs.dsmXscale);
    dsmRegs.dsmXoffset = double(dsmRegs.dsmXoffset);
    dsmRegs.dsmYscale = double(dsmRegs.dsmYscale);
    dsmRegs.dsmYoffset = double(dsmRegs.dsmYoffset);
    
    preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acData, dsmRegs, KRaw, rot90(currentFrame.relevantPixelsImage,2), params.maxLosScalingStep);
    dsmData.preProcData=preProcData;
    dsmData.preProcData.relevantPixelnImage_rot = rot90(currentFrame.relevantPixelsImage,2);
    losShift = zeros(2,1); % any residual LOS shift is reflected onto RGB principle point and/or extrinsic translation
    [losScaling, optScaling, focalScaling, errL2, sgMat, quadCoef, sg_mat_tag_x_sg_mat, sg_mat_tag_x_err_l2] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, newKRaw);
    dsmData.focalScaling = focalScaling;
    dsmData.errL2 = errL2;
    dsmData.sg_mat_tag_x_sg_mat = sg_mat_tag_x_sg_mat;
    dsmData.sg_mat_tag_x_err_l2 = sg_mat_tag_x_err_l2;  
    dsmData.quadCoef = quadCoef;
    dsmData.sgMat = sgMat;
    dsmData.optScaling = optScaling;
    dsmData.newlosScaling = losScaling;
    acDataCand = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acData, acData.flags(1), losShift, losScaling);
    dsmRegsCand = Utils.convert.applyAcResOnDsmModel(acDataCand, dsmRegsOrig, 'direct');
%         acDataInCand.flags(2:6) = uint8(0);
    % Apply the new scaling to xim and yim for next iteration
    % Transforming pixels to LOS
    scVertices = currentFrame.vertices;
    scVertices(:,1:2) = -scVertices(:,1:2);
    los = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegs, scVertices);
    dsmData.orig_los = los;
    [newVertices, dsmX,dsmY] = OnlineCalibration.K2DSM.ConvertLosToNormVertices(regs, dsmRegsCand, los);
    
    dsmData.dsm = [ dsmX dsmY];
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

