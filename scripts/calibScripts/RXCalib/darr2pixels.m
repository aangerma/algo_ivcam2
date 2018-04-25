function [pIR,pDepth] = darr2pixels(dstr,savePath)
%% Get for each pixel his IR values and depth
[nDist,nIllum] = size(dstr);
nPixelsInImage = numel(dstr(1).i);
nPixels = nDist*nPixelsInImage;
pIR = zeros(nPixels,nIllum);
pDepth = zeros(nPixels,nIllum);
for j = 1:nDist
    for i = 1:nIllum
        validP = dstr(j,i).valid(:);
        pIR((j-1)*nPixelsInImage+1:j*nPixelsInImage,i) = dstr(j,i).i(:).*validP;
        pDepth((j-1)*nPixelsInImage+1:j*nPixelsInImage,i) = dstr(j,i).z(:)/8.*validP;
    end
end
invalidPixels = sum(pIR>0,2)<=5; 
pIR(invalidPixels,:) = [];
pDepth(invalidPixels,:) = [];

pDepthNoZeros = pDepth;pDepthNoZeros(pDepthNoZeros==0) = inf;
% histogram(max(pDepth,[],2)-min(pDepthNoZeros,[],2))
badDepth = (max(pDepth,[],2)-min(pDepthNoZeros,[],2)) > 10;
pIR(badDepth,:) = [];
pDepth(badDepth,:) = [];

save(savePath,'pIR','pDepth');
end

