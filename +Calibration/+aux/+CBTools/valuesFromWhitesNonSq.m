function [rtdFromWhite,ptsFromWhite1,ptsFromWhite2,pts,colorMap] = valuesFromWhitesNonSq(rtd,pts,colorMap,r)
%VALUESFROMWHITES Takes the values of the rtd from the white corners
%instead of the corners themselves

%For this function to work on a full checkerboard, we need to pad pts and colors with nans
sz = size(colorMap);
pts = padarray(pts,[1 1],nan,'both');
colorMap = padarray(colorMap,[1 1],nan,'both');

validPts = ~isnan(pts);
ptsFromWhite1 = nan([size(colorMap),2]);
ptsFromWhite2 = nan([size(colorMap),2]);

colorMapXY = cat(3,colorMap,colorMap);

% Update inner whites
whites = colorMapXY == 1;
ptsFromWhite1(whites) = pts(circshift(whites,[1,1,0]));
ptsFromWhite2(whites) = pts(circshift(whites,[-1,-1,0]));
% Update inner blacks
blacks = colorMapXY == 0;
ptsFromWhite1(blacks) = pts(circshift(blacks,[-1,1,0]));
ptsFromWhite2(blacks) = pts(circshift(blacks,[1,-1,0]));

% figure;subplot(121);imagesc(~isnan(ptsFromWhite1(:,:,2)));subplot(122);imagesc(~isnan(ptsFromWhite2(:,:,2)));

% For each point with a single nan, add a reflection
singleNans = validPts(:,:,1) & xor(~isnan(ptsFromWhite1(:,:,1)),~isnan(ptsFromWhite2(:,:,1)));
singleNans1 = singleNans & ~isnan(ptsFromWhite1(:,:,1));
singleNans1 = cat(3,singleNans1,singleNans1);
singleNans2 = singleNans & ~isnan(ptsFromWhite2(:,:,1));
singleNans2 = cat(3,singleNans2,singleNans2);

ptsFromWhite1(singleNans2) = 2*pts(singleNans2) - ptsFromWhite2(singleNans2);
ptsFromWhite2(singleNans1) = 2*pts(singleNans1) - ptsFromWhite1(singleNans1);

% figure;subplot(121);imagesc(~isnan(ptsFromWhite1(:,:,2)));subplot(122);imagesc(~isnan(ptsFromWhite2(:,:,2)));


% For each valid point with 2 nans, take from a diagonal friend
for i = [-1,1]
    for j = [-1,1]
        doubleNans = validPts(:,:,1) & (isnan(ptsFromWhite1(:,:,1)) & isnan(ptsFromWhite2(:,:,1)));
        doubleNans = cat(3,doubleNans,doubleNans);
        ptsFromWhite1(doubleNans) = pts(doubleNans) + ptsFromWhite1(circshift(doubleNans,[i,j,0])) -  pts(circshift(doubleNans,[i,j,0]));
        ptsFromWhite2(doubleNans) = pts(doubleNans) + ptsFromWhite2(circshift(doubleNans,[i,j,0])) -  pts(circshift(doubleNans,[i,j,0]));
    end
end

% figure;subplot(121);imagesc(~isnan(ptsFromWhite1(:,:,2)));subplot(122);imagesc(~isnan(ptsFromWhite2(:,:,2)));

% Crop back to original size
ptsFromWhite1 = ptsFromWhite1(2:end-1,2:end-1,:);
ptsFromWhite2 = ptsFromWhite2(2:end-1,2:end-1,:);
pts = pts(2:end-1,2:end-1,:);
colorMap = colorMap(2:end-1,2:end-1,:);
ptsFromWhite1 = r*(ptsFromWhite1-pts) + pts;
ptsFromWhite2 = r*(ptsFromWhite2-pts) + pts;
ptsFromWhite1 = reshape(ptsFromWhite1,[],2);
ptsFromWhite2 = reshape(ptsFromWhite2,[],2);

rtdFromWhite = interp2(rtd,ptsFromWhite1(:,1),ptsFromWhite1(:,2))*0.5 + interp2(rtd,ptsFromWhite2(:,1),ptsFromWhite2(:,2))*0.5;
if ~(sum(~isnan(pts(:))) ==  sum(~isnan(ptsFromWhite1(:)))) || ~(sum(~isnan(pts(:))) ==  sum(~isnan(ptsFromWhite2(:))))
    warning('Failed to get values from white squares. Input valid points ~= input valid points. Removing some corners.');
    doubleNans = (isnan(ptsFromWhite1(:,1)) & isnan(ptsFromWhite2(:,1)));
    pts = reshape(pts,[],2);
    pts(doubleNans) = nan;
    pts = reshape(pts,[sz,2]);
    colorMap = reshape(colorMap,[],1);
    colorMap(doubleNans) = nan;
    colorMap = reshape(colorMap,sz);
end

end
