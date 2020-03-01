function [C,scorePerVertex] = calculateCost(V,W,D,camerasParams)
%     [Dx,Dy] = imgradientxy(D);% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]
%     A = camerasParams.rgbPmat;
    uvMap = OnlineCalibration.aux.projectVToRGB(V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
% 
%     validPts = uvMap > 0;
%     validPts = validPts & (uvMap(:,1) < size(D,2)-1);
%     validPts = validPts & (uvMap(:,2) < size(D,1)-1);
%     validPts = all(validPts,2);
%     
%     W = W(validPts);
%     uvMap = uvMap(validPts,:);
    
    DVals = interp2(single(D),uvMap(:,1)+1,uvMap(:,2)+1);
    scorePerVertex = W.*DVals;
    C = nanmean(scorePerVertex);
%     
%     DxVal = interp2(single(Dx),uvVals(:,1)+1,uvVals(:,2)+1);
%     DyVal = interp2(single(Dy),uvVals(:,1)+1,uvVals(:,2)+1);
%     for k = 1:numel(EVals)
%         Ax = [VVal(k,:)/dot(A(3,:),VVal(k,:));...
%               zeros(1,4);...
%               - dot(A(1,:),VVal(k,:))*VVal(k,:)/ (dot(A(1,:),VVal(k,:))^2) ];
%         Ay = [zeros(1,4);...
%               VVal(k,:)/dot(A(3,:),VVal(k,:));...
%               - dot(A(2,:),VVal(k,:))*VVal(k,:)/ (dot(A(1,:),VVal(k,:))^2) ];
%         gCbyA(:,:,k) = EVals(k)*(DxVal(k)*Ax + DyVal(k)*Ay);
%     end
%     grad = mean(gCbyA,3);
%     grad = grad/norm(grad);
%     
%     j = 1;
%     for nrm = linspace(-0.02,0.02,100)
%         Am = A + nrm*grad;
%         camerasParams.rgbPmat = Am;
%         
%         uvMap = projectVToRGB(V,camerasParams);
%         validPts = uvMap > 0;
%         validPts = validPts & (uvMap(:,1) < size(D,2)-1);
%         validPts = validPts & (uvMap(:,2) < size(D,1)-1);
%         validPts = all(validPts,2);
% 
%         VVal = V(validPts,:);
%         VVal = [VVal,ones(size(VVal,1),1)];
%         EVals = single(Ez(validPts,:));
%         uvVals = uvMap(validPts,:);
%         DVals = interp2(single(D),uvVals(:,1)+1,uvVals(:,2)+1);
%         C = mean(EVals.*DVals);
%         e(j) = C;
%         j = j + 1;
%     end
end