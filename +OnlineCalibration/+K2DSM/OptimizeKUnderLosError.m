function K = OptimizeKUnderLosError(data, losScaling, optLosShift)
    
    nErrModels = size(losScaling,1);
    K = zeros(3, 3, nErrModels);
    for iErrModel = 1:nErrModels
        % applying angular error
        losX = losScaling(iErrModel,1)*data.losOrig(:,1) + optLosShift(1);
        losY = losScaling(iErrModel,2)*data.losOrig(:,2) + optLosShift(2);
        updatedVertices = OnlineCalibration.K2DSM.ConvertLosToNormVertices(data.regs, data.dsmRegs, [losX, losY]); % forward model: vertices calculation assuming LOS error, using current camera state
        updatedPixels = updatedVertices * data.origK';
        
        % optimizing K
        nPts = size(data.verticesOrig,1);
        V = [data.verticesOrig(:,[1,3]), zeros(nPts,2); zeros(nPts,2), data.verticesOrig(:,[2,3])]; % ideal vertices calculation assuming error-free LOS
        P = [updatedPixels(:,1); updatedPixels(:,2)];
        kVec = OnlineCalibration.K2DSM.DirectInv(V'*V)*(V'*P); % direct implementation of Matlab's solver: (V'*V)\(V'*P)
        K(:,:,iErrModel) = [kVec(1), 0, kVec(2); 0, kVec(3), kVec(4); 0, 0, 1];
    end
    
end