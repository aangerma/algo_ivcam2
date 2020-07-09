function [isMovement,movingPixels] = isMovementInImages(im1,im2, params,outputBinFilesPath)
isMovement = false;

[edgeIm1,~,~] = OnlineCalibration.aux.edgeSobelXY(uint8(im1));
logicEdges = abs(edgeIm1) > params.edgeThresh4logicIm*max(edgeIm1(:));

SE = strel('square', params.seSize);
dilatedIm = imdilate(logicEdges,SE);

% diffIm = abs(im1-im2);
diffIm = imgaussfilt(double(im1)-double(im2),params.moveGaussSigma);
IDiffMasked = abs(diffIm);
IDiffMasked(dilatedIm) = 0;
% figure; imagesc(IDiffMasked); title('IDiffMasked');impixelinfo; colorbar;
ixMoveSuspect = IDiffMasked > params.moveThreshPixVal; 
if sum(ixMoveSuspect(:)) > params.moveThreshPixNum
    isMovement = true;
end
movingPixels = sum(ixMoveSuspect(:));
% disp(['isMovementInImages: # of pixels above threshold ' num2str(sum(ixMoveSuspect(:))) ', allowed #: ' num2str(params.moveThreshPixNum)]);

if nargin > 3
    if exist('outputBinFilesPath','var') && ~isempty(outputBinFilesPath)
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'logicEdges',uint8(logicEdges),'uint8');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'dilatedIm',double(dilatedIm),'double');
        diffIm_01 = (double(im1)-double(im2));
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'diffIm_01',diffIm_01,'double');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'diffIm',double(diffIm),'double');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'IDiffMasked',double(IDiffMasked),'double');
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'ixMoveSuspect',uint8(ixMoveSuspect),'uint8');
    end
end
end

