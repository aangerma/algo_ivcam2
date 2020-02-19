function [subEdgeIm,suppresedE,closeEdgeVal] = subpixelEdges(Z,edgeTh,IREdgeMask)
% Returns an image with 3 channels, the first channel is the edge image
% after non-maximal suppresion. The second and third channels are the
% subpixel locations of the edge. The fourth channel

sz = size(Z); 
[gridX,gridY] = meshgrid(1:sz(2),1:sz(1)); % gridX/Y contains the indices of the pixels

[Ix,Iy] = imgradientxy(single(Z));% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]
E = sqrt(Ix.^2+Iy.^2);
E(E<edgeTh) = 0;
E(~IREdgeMask) = 0;
directionInDeg = mod(atan2d(Iy,Ix),180);% For each pixel, we can calculate the direction of the gradient in degrees
[~,dirI] = min(abs(directionInDeg(:) - [0:45:135]),[],2); % Quantize the direction to 4 directions (don't care about the sign)
dirI = reshape(dirI,size(E));
dirsVec = [0,1; 1,1; 1,0; 1,-1]; % These are the 4 directions

subPixelGrads = [];
subEdgeIm = nan([size(Z),2]);
closeEdgeVal = nan(size(Z));
for d = 1:size(dirsVec,1)% Do it for every direction
    currDir= dirsVec(d,:);
    E_plus = circshift(E,-currDir); 
    E_minus = circshift(E,+currDir);
    E_edge = (E >= E_plus) & (E >= E_minus) & (E>0);

    fraqStep = vec(-0.5*(E_plus-E_minus)./(E_plus+E_minus-2*E)); % The step we need to move to reach the subpixel gradient i nthe gradient direction
    subGrad = fraqStep.*currDir;
    subGrad = subGrad + [gridY(:),gridX(:)];% the location of the subpixel gradient
    validE = E_edge>0 & dirI==d;
    
    subGradImage = subGrad(validE(:),:); 
    subEdgeIm(cat(3,validE,validE)) = fliplr(subGradImage);
    
    % Take the value 
    I_plus = circshift(Z,-currDir);
    I_minus = circshift(Z,+currDir);
    I_closest = min(I_plus,I_minus);
    closeEdgeVal(validE) = I_closest(validE);
end

E(isnan(subEdgeIm(:,:,1))) = 0;

suppresedE = E;
closeEdgeVal(~IREdgeMask) = 0;

end

