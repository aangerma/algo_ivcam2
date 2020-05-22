function K = OptimizeKUnderLosErrorSim(origK, vertices, xPixInterpolant, yPixInterpolant, origLos, errPolyCoef)
     
     nErrModels = size(errPolyCoef,1);
     K = zeros(3, 3, nErrModels);
     for iErrModel = 1:nErrModels
         % applying angular error
         losX = polyval(errPolyCoef(iErrModel,:,1), origLos(:,1));
         losY = polyval(errPolyCoef(iErrModel,:,2), origLos(:,2));
         pixX = xPixInterpolant(losX, losY);
         pixY = yPixInterpolant(losX, losY);
         % optimizing K
         V = [vertices(:,1), zeros(size(vertices,1),1); zeros(size(vertices,1),1), vertices(:,2)];
         P = [pixX - origK(1,3)*vertices(:,3); pixY - origK(2,3)*vertices(:,3)];
         kVec = (V'*V)\V'*P;
        K(:,:,iErrModel) = [kVec(1), 0, origK(1,3); 0, kVec(2), origK(2,3); 0, 0, 1];
     end
     
 end

