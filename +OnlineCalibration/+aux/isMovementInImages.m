function [isMovement] = isMovementInImages(im1,im2, params)
isMovement = false;

[edgeIm1,~,~] = OnlineCalibration.aux.edgeSobelXY(uint8(im1));
logicEdges = abs(edgeIm1) > params.edgeThresh4logicIm*max(edgeIm1(:));

SE = strel('square', params.seSize);
dilatedIm = imdilate(logicEdges,SE);

% diffIm = abs(im1-im2);
diffIm = imgaussfilt(im1-im2,params.moveGaussSigma);
IDiffMasked = abs(diffIm);
IDiffMasked(dilatedIm) = 0;
% figure; imagesc(IDiffMasked); title('IDiffMasked');impixelinfo; colorbar;
ixMoveSuspect = IDiffMasked > params.moveThreshPixVal; 
if sum(ixMoveSuspect(:)) > params.moveThreshPixNum
    isMovement = true;
end
  
disp(['isMovementInImages: # of pixels above threshold ' num2str(sum(ixMoveSuspect(:))) ', allowed #: ' num2str(params.moveThreshPixNum)]);
end

