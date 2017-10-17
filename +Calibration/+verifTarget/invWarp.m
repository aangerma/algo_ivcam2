function [Iw,x0] = invWarp(I,H,optimalInterestPoints)
%does inverse warping on image I with transformation matrix H.
%optimalInterestPoints are the points by which we found the H, so to gat a
%region of interest.

%% first- get the frame we want to inverse transform
[xOrig,yOrig] = meshgrid(1:size(I,2),1:size(I,1));
% forwardP = H*[xOrig(:).';yOrig(:).';ones(size(yOrig(:).'))];
% forwardP = forwardP(1:2,:)./forwardP(3,:);
% 
% minx = floor(min(forwardP(1,:)));
% maxx = ceil(max(forwardP(1,:)));
% miny = floor(min(forwardP(2,:)));
% maxy = ceil(max(forwardP(2,:)));
minx = floor(min(optimalInterestPoints(:,1)));
maxx = ceil(max(optimalInterestPoints(:,1)));
miny = floor(min(optimalInterestPoints(:,2)));
maxy = ceil(max(optimalInterestPoints(:,2)));

xRegion = floor(minx-(maxx-minx)/5):ceil(maxx+(maxx-minx)/5);
yRegion = floor(miny-(maxy-miny)/5):ceil(maxy+(maxy-miny)/5);

[xTrans,yTrans] = meshgrid(xRegion,yRegion);

x0 = [xTrans(1) yTrans(1)];

%% do inverse transform on new frame
invP = H\[xTrans(:).';yTrans(:).';ones(size(yTrans(:).'))];
invP = invP(1:2,:)./invP(3,:);

Iw = reshape(interp2(xOrig,yOrig,double(I),invP(1,:).',invP(2,:).','spline',0),size(xTrans));

if(0)
%     figure;hold on
%     scatter(xTrans(:),yTrans(:))
%     scatter(invP(1,:),invP(2,:))
    figure(3521);hold on;
    scatter(xOrig(1:50:end),yOrig(1:50:end)); scatter(forwardP(1,1:50:end),forwardP(2,1:50:end))
    

    figure(2399951);imagesc(xTrans(:),yTrans(:),Iw);
end
end

