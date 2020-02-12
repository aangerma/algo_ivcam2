function [subEdgeIm,suppresedE,closeEdgeVal] = subpixelEdges(I,edgeTh)
% Returns an image with 3 channels, the first channel is the edge image
% after non-maximal suppresion. The second and third channels are the
% subpixel locations of the edge. The fourth channel

sz = size(I);
[gridX,gridY] = meshgrid(1:sz(2),1:sz(1));

[Ix,Iy] = imgradientxy(single(I));% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]
E = sqrt(Ix.^2+Iy.^2);
E(E<edgeTh) = 0;

direction = mod(atan2d(Iy,Ix),180);
[~,dirI] = min(abs(direction(:) - [0:45:135]),[],2);
dirsVec = [0,1; 1,1; 1,0; 1,-1];

subPixelGrads = [];
subEdgeIm = nan([size(I),2]);
closeEdgeVal = nan(size(I));
for d = 1:size(dirsVec,1)
    currDir= dirsVec(d,:);
    E_plus = circshift(E,-currDir);
    E_minus = circshift(E,+currDir);
    E_edge = (E >= E_plus) & (E >= E_minus) & (E>edgeTh);

    fraqStep = vec(-0.5*(E_plus-E_minus)./(E_plus+E_minus-2*E));
    subGrad = fraqStep.*currDir;
    subGrad = subGrad + [gridY(:),gridX(:)];
    validE = reshape((E_edge(:)>0  & dirI==d),size(E));
    
    subGradImage = subGrad(validE(:),:); 
    subEdgeIm(cat(3,validE,validE)) = fliplr(subGradImage);
    
    
    I_plus = circshift(I,-currDir);
    I_minus = circshift(I,+currDir);
    I_closest = min(I_plus,I_minus);
    closeEdgeVal(validE) = I_closest(validE);
end

E(isnan(subEdgeIm(:,:,1))) = 0;

suppresedE = E;

end

