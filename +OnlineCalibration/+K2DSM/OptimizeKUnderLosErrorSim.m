function K = OptimizeKUnderLosErrorSim(vertices, xPixInterpolant, yPixInterpolant, origLos, errPolyCoef)
    
    nErrModels = size(errPolyCoef,1);
    K = zeros(3, 3, nErrModels);
    for iErrModel = 1:nErrModels
        % applying angular error
        losX = polyval(errPolyCoef(iErrModel,:,1), origLos(:,1));
        losY = polyval(errPolyCoef(iErrModel,:,2), origLos(:,2));
        pixX = xPixInterpolant(losX, losY);
        pixY = yPixInterpolant(losX, losY);
        % optimizing K
        V = [vertices(:,[1,3]), zeros(size(vertices,1),2); zeros(size(vertices,1),2), vertices(:,[2,3])];
        P = [pixX; pixY];
        kVec = (V'*V)\V'*P;
        K(:,:,iErrModel) = [kVec(1), 0, kVec(2); 0, kVec(3), kVec(4); 0, 0, 1];
    end
    
end