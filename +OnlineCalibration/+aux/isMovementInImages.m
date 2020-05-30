function [isMovement,movingPixels] = isMovementInImages(im1,im2, params,outputBinFilesPath)
isMovement = false;

[edgeIm1,~,~] = OnlineCalibration.aux.edgeSobelXY(uint8(im1));
logicEdges = abs(edgeIm1) > params.edgeThresh4logicIm*max(edgeIm1(:));

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'logicEdges',uint8(logicEdges),'uint8');

SE = strel('square', params.seSize);
dilatedIm = imdilate(logicEdges,SE);

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'dilatedIm',double(dilatedIm),'double');
diffIm = (double(im1)-double(im2));
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'diffIm_01',diffIm,'double');

% diffIm = abs(im1-im2);
diffIm = imgaussfilt(im1-im2,params.moveGaussSigma);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'diffIm',double(diffIm),'double');

IDiffMasked = abs(diffIm);
IDiffMasked(dilatedIm) = 0;

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'IDiffMasked',double(IDiffMasked),'double');

% figure; imagesc(IDiffMasked); title('IDiffMasked');impixelinfo; colorbar;
ixMoveSuspect = IDiffMasked > params.moveThreshPixVal; 
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'ixMoveSuspect',uint8(ixMoveSuspect),'uint8');

if sum(ixMoveSuspect(:)) > params.moveThreshPixNum
    isMovement = true;
end
movingPixels = sum(ixMoveSuspect(:));
% disp(['isMovementInImages: # of pixels above threshold ' num2str(sum(ixMoveSuspect(:))) ', allowed #: ' num2str(params.moveThreshPixNum)]);
end

