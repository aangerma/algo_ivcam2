function [] = calbDFAnalysis(d,regs)
close all
% Apply undistortion to d.i and d.z
[e,source,dest]=Calibration.aux.evalProjectiveDisotrtion(d.i);
[undistx,undisty]=generateUndistTables(source,dest,size(d.i));

[yg,xg]=ndgrid(1:480,1:640);
fixedX = xg+undistx;
fixedY = yg+undisty;
d.i=griddata(fixedY,fixedX,double(d.i),yg,xg);
d.z=griddata(fixedY,fixedX,double(d.z),yg,xg);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


regs.DEST.txFRQpd = 5000;
%some filtering 
%%%%%%%%%%%%%%remove holes%%%%%%%%%%%%%%%
im = double(d.i);
im(im==0)=nan;
N=3;
imv = im(Utils.indx2col(size(im),[N N]));
bd = vec(isnan(im));
im(bd)=nanmedian_(imv(:,bd));
%%%%%%%%%%%%%%Find Checkerboard corners%%%%%%%%%%%%%%%
[p,bsz] = detectCheckerboardPoints(normByMax(im));

%%%%%%%%%%%%%%Calculate round trip distance (rtd)%%%%%%%%%%%%%%%
[~,r] = Pipe.z16toVerts(d.z,regs);
[~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd=r+sqrt(r.^2-C);
[yg,xg]=ndgrid(1:size(rtd,1),1:size(rtd,2));
it = @(k) interp2(xg,yg,k,reshape(p(:,1),bsz-1),reshape(p(:,2),bsz-1));



% View how the points change as a function of system delay.
figure
SD = 0:500:7000;
for i = 1:numel(SD)
    X = double([regs.FRMW.xfov regs.FRMW.yfov SD(i)]);
    v = x2v(rtd,it,X);
    [~,ptsOut] = Calibration.aux.evalGeometricDistortion(v);
    points = reshape(v,[],3)';
    pointsFitted = reshape(ptsOut,[],3)';
    tabplot;
    plot3(points(1,:),points(2,:),points(3,:),'*',pointsFitted(1,:),pointsFitted(2,:),pointsFitted(3,:),'o')
    title(sprintf('txFRQpd=%5d',SD(i)))
    axis([-2000        2000       -2000        2000      0        2953])
    view(170, 10);
    xlabel('x'),ylabel('y'),zlabel('z'),grid on
end
linkprop(findobj(gcf,'type','axes'),{'xlim','ylim','zlim','CameraTarget','CameraUpVector','CameraPosition'})
% View how the points change as a function of FOV Y.
figure
FOVY = 20:5:90;
for i = 1:numel(FOVY)
    X = double([regs.FRMW.xfov FOVY(i) regs.DEST.txFRQpd(1)]);
    v = x2v(rtd,it,X);
    [~,ptsOut] = Calibration.aux.evalGeometricDistortion(v);
    points = reshape(v,[],3)';
    pointsFitted = reshape(ptsOut,[],3)';
    tabplot;
    plot3(points(1,:),points(2,:),points(3,:),'*',pointsFitted(1,:),pointsFitted(2,:),pointsFitted(3,:),'o')
    title(sprintf('FOV Y=%2d',FOVY(i)))
    axis([-2000        2000       -2000        2000      0        2953])
    view(176, 38);
    xlabel('x'),ylabel('y'),zlabel('z'),grid on
end
linkprop(findobj(gcf,'type','axes'),{'xlim','ylim','zlim','CameraTarget','CameraUpVector','CameraPosition'})
% View how the points change as a function of FOV X.
figure
FOVX = 20:5:90;
for i = 1:numel(FOVX)
    X = double([FOVX(i) regs.FRMW.yfov regs.DEST.txFRQpd(1)]);
    v = x2v(rtd,it,X);
    [~,ptsOut] = Calibration.aux.evalGeometricDistortion(v);
    points = reshape(v,[],3)';
    pointsFitted = reshape(ptsOut,[],3)';
    tabplot;
    plot3(points(1,:),points(2,:),points(3,:),'*',pointsFitted(1,:),pointsFitted(2,:),pointsFitted(3,:),'o')
    title(sprintf('FOV X=%2d',FOVY(i)))
    axis([-2000        2000       -2000        2000      0        4000])
    view(176, 38);
    xlabel('x'),ylabel('y'),zlabel('z'),grid on
end
linkprop(findobj(gcf,'type','axes'),{'xlim','ylim','zlim','CameraTarget','CameraUpVector','CameraPosition'})

% Try to use fmin to optimize the regs
x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1)]);
xL = [20 20 0000];
xH = [90 90 65000];

opt.maxIter=1000;
opt.OutputFcn=[];
opt.Display='iter';
plotProgress = 1;
figure
[xbest,minerr]=fminsearchbnd(@(x) errFunc(rtd,it,x,plotProgress),x0,xL,xH,opt);
linkprop(findobj(gcf,'type','axes'),{'xlim','ylim','zlim','CameraTarget','CameraUpVector','CameraPosition'})
end

function [e,v]=errFunc(rtd,it,X,plotProgress)
v = x2v(rtd,it,X);
[e,pOut] = Calibration.aux.evalGeometricDistortion(v);
if plotProgress
    points = reshape(v,[],3)';
    pointsFitted = reshape(pOut,[],3)';
    tabplot;
    plot3(points(1,:),points(2,:),points(3,:),'*',pointsFitted(1,:),pointsFitted(2,:),pointsFitted(3,:),'o')
    axis([-2000        2000       -2000        2000      0        4000])
    view(176, 38);
    title(sprintf('FOVXY = [%2d,%2d], SD = %5d',X(1),X(2),X(3)))
    xlabel('x'),ylabel('y'),zlabel('z'),grid on
end
end
function v = x2v(rtd,it,X)
regs=x2regs(size(rtd),X);
trigoRegs = Pipe.DEST.FRMW.trigoCalcs(regs);
trigoRegs.MTLB.fastApprox=true(1,8);
trigoRegs.DEST.hbaseline=false;
trigoRegs.DEST.baseline=30;
trigoRegs.DEST.baseline2=trigoRegs.DEST.baseline^2;
trigoRegs.DEST.depthAsRange=false;
rtd_=rtd-regs.DEST.txFRQpd(1);
[z,~,x,y]=Pipe.DEST.rtd2depth(rtd_,trigoRegs);
v=cat(3,it(x),it(y),it(z));
end
function regs=x2regs(sz,x)
regs.FRMW.xfov=x(1);
regs.FRMW.yfov=x(2);
regs.FRMW.gaurdBandH=0;
regs.FRMW.gaurdBandV=0;
regs.FRMW.xres=sz(2);
regs.FRMW.yres=sz(1);
regs.FRMW.marginL=0;
regs.FRMW.marginT=0;

regs.FRMW.xoffset=0;
regs.FRMW.yoffset=0;
regs.FRMW.undistXfovFactor=1;
regs.FRMW.undistYfovFactor=1;
regs.DEST.txFRQpd=[1 1 1]*x(3);
regs.DIGG.undistBypass = false;
regs.FRMW.undistXfovFactor=1;
regs.FRMW.undistYfovFactor=1;
regs.GNRL.rangeFinder=false;

end

function [undistx,undisty] = generateUndistTables(s,d,wh)
pmargin = 0.1;

wh=fliplr(wh);

x0 = -ceil(wh(1)*pmargin);
x1 =  ceil(wh(1)*(1+pmargin));
y0 = -ceil(wh(2)*pmargin);
y1 =  ceil(wh(2)*(1+pmargin));
distortionH=y1-y0;
distortionW=x1-x0;



bdpts=interp1(0:4,[0 0;1 0;1 1;0 1;0 0],(0:0.1:4))'.*[distortionW;distortionH]+[x0;y0];
s=[s bdpts];d=[d bdpts];
tps=TPS(s',d'-s'); % We look for a mapping between each point and the undistortion vector.

[yg,xg]=ndgrid(1:wh(2),1:wh(1));
undist=tps.at([xg(:) yg(:)]);
undistx=reshape(undist(:,1),size(xg));
undisty=reshape(undist(:,2),size(yg));

% 
% quiver(s(1,:),s(2,:),d(1,:)-s(1,:),d(2,:)-s(2,:))
% rectangle('position',[1 1 wh])
% hold on
% quiver(xg,yg,undistx,undisty)
% hold off
end