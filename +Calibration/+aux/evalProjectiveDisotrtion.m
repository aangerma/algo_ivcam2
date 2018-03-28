function [e,s,d,inliers] = evalProjectiveDisotrtion(varargin)
if(nargin==1)
    im = varargin{1};
    % find checkboard corners
    im = double(im);
    im(im==0)=nan;
    N=3;
    imv = im(Utils.indx2col(size(im),[N N]));
    bd = vec(isnan(im));
    im(bd)=nanmedian_(imv(:,bd));
%      im=reshape(nanmedian(imv),size(im));
    
    [p,bsz] = detectCheckerboardPoints(normByMax(im));
    bsz=bsz-1;
elseif(nargin==2)
    p = varargin{1};
    bsz = varargin{2};
    im=0; %#ok<*NASGU>
else
    error('Either 1 image input, or two points+board size inputs');
end

%build optimal grid
[yg,xg]=ndgrid(linspace(-1,1,bsz(1)),linspace(-1,1,bsz(2)));

%{
% using LS, find the homography s.t:
s=[x;y;1]
d=[u;v;w];
d = H*s
H=[a b c;d e f;g h 1];
u=(ax+by+cz)/(gx+hy+1)
v=(ae+fy+gz)/(gx+hy+1)
using LS:

|x y 1 0 0 0 -ux -uy| |a  |     |u|
|0 0 0 x y 1 -vx -vy| |b  |  = -|v|
                      |.. |
                      |h  |
                      

%}


inliers=true(numel(xg),1);
for i=1:3
    n=nnz(inliers);
    oo= [xg(inliers) yg(inliers) ones(n,1)];
    zr = zeros(n,3);
    h=[oo zr  -oo(:,1:2).*p(inliers,1);
        zr oo  -oo(:,1:2).*p(inliers,2)
        ];
    x   = h\vec(p(inliers,:));
    hh=reshape([x;1],3,3);
    d = [xg(:) yg(:) ones(numel(xg),1)]*hh;
    d=d(:,1:2)./d(:,3);
    
    ev = sqrt(sum((d-p).^2,2));
    inliers = inliers & ev<prctile_(ev,90);
end
e = sqrt(mean(ev.^2));


s=p';
d=d';

if(0)
    %%
figure(343424);
aa(1)=subplot(121);
imagesc(im);title('Input');
hold on
plot(d(1,:),d(2,:),'.g',s(1,:),s(2,:),'ro');axis image
colormap gray
hold off
aa(2)=subplot(122);
quiver(s(1,:),s(2,:),d(1,:)-s(1,:),d(2,:)-s(2,:),'k');title(sprintf('Output (rms err = %f)',e));
set(aa(2),'ydir','reverse');
axis image
linkaxes(aa);
drawnow;
end
end