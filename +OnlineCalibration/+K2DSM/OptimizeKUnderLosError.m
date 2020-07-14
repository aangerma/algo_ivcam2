function K = OptimizeKUnderLosError(data, losScaling)
    
    nErrModels = size(losScaling,1);
    K = zeros(3, 3, nErrModels);
    for iErrModel = 1:nErrModels
        % applying angular error
        losX = losScaling(iErrModel,1)*data.losOrig(:,1);
        losY = losScaling(iErrModel,2)*data.losOrig(:,2);
        updatedVertices = OnlineCalibration.K2DSM.ConvertLosToNormVertices(data.regs, data.dsmRegs, [losX, losY]); % forward model: vertices calculation assuming LOS error, using current camera state
        updatedPixels = updatedVertices * data.origK';
        
        % optimizing K
        nPts = size(data.verticesOrig,1);
        V = [data.verticesOrig(:,1), zeros(nPts,1); zeros(nPts,1), data.verticesOrig(:,2)]; % ideal vertices calculation assuming error-free LOS
        P = [updatedPixels(:,1) - data.origK(1,3)*data.verticesOrig(:,3); updatedPixels(:,2) - data.origK(2,3)*data.verticesOrig(:,3)];
        %kVec = OnlineCalibration.K2DSM.DirectInv(V'*V)*(V'*P); % direct implementation of Matlab's solver: (V'*V)\(V'*P)
        kVec = (V'*V)\(V'*P);
        K(:,:,iErrModel) = [kVec(1), 0, data.origK(1,3); 0, kVec(2), data.origK(2,3); 0, 0, 1];
    end
    
end