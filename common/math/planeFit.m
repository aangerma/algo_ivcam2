function [d ,distFromPlane,inliers] = planeFit(x,y,z,fovMask,crit,verbose)
FIT_DEG = 1;%plane
if(~exist('fovMask','var') || isempty(fovMask))
    fovMask = ones(numel(x),1);
end
if(~exist('crit','var'))
    crit = inf;%no outliyer removal
end
if(~exist('verbose','var'))
    verbose = false;
end

if(numel(x)<10)
    d=zeros(4,1);
    distFromPlane=zeros(size(x));
    inliers=fovMask;
    return;
end
xyzc=[x(:) y(:) z(:)];
inliers =fovMask(:) & ~isnan(any(xyzc,2)) & ~isinf(any(xyzc,2));

for i=1:2
    %generate model
H = generateLSH(xyzc(inliers,:),FIT_DEG);
[v,~] = eig(H'*H);
d = v(:,1);
d = d/sqrt(sum(d(1:3).^2));
%remove outliers
distFromPlane = generateLSH(xyzc,FIT_DEG)*d;
inliers = (abs(distFromPlane)<crit) & inliers;
end

distFromPlane = reshape(distFromPlane,size(x));
inliers = reshape(inliers,size(x));

if(verbose)
    xyzcOnPlane=permute(cat(3,xyzc,xyzc-d(1:3)'.*distFromPlane'),[3 1 2]);
    plot3(x(:),y(:),z(:),'ro');
    plotPlane(d,'edgecolor','none','facecolor','b','facealpha',.1);
    line(xyzcOnPlane(:,inliers,1),xyzcOnPlane(:,inliers,2),xyzcOnPlane(:,inliers,3),'color','g')
    line(xyzcOnPlane(:,~inliers,1),xyzcOnPlane(:,~inliers,2),xyzcOnPlane(:,~inliers,3),'color','r')
    axis equal
end
end