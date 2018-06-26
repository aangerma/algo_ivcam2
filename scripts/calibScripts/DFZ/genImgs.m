% function genImg
clear;
xfov=72;
yfov=56;
xres=640;
yres=480;
bl=30;%mm
projectionYshear=0;
targetDistance = 500;
deg2rad=pi/180;
planeRotMat=rotation_matrix(deg2rad*9,deg2rad*20,deg2rad*2);
k=[
0.5*(xres)/tand(xfov/2) 0                      (xres)/2;
0                      0.5*(yres)/tand(yfov/2) (yres)/2;
0                      0                       1
];
laserAngX=0;
laserAngY=0;

%%
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx) sind(angy) cosd(angx).*cosd(angy)]';
laserIncidentDirection = angles2xyz( laserAngX, laserAngY+180); %+180 because the vector direction is toward the mirror
xyz2nrmxy= @(xyz) xyz(1:2,:)./xyz(3,:);
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
arr2cmplx=@(x) iff(size(x,1)==2,x(1,:)+1j*x(2,:),x(:,1)+1j*x(:,2));


p=Calibration.getTargetParams();
ny=p.cornersY+2;
nx=p.cornersX+2;
[oy,ox]=ndgrid(linspace(-1,1,ny)*(ny-1)*p.mmPerUnitY/2,linspace(-1,1,nx)*(nx-1)*p.mmPerUnitY/2);
og = [ox(:) oy(:) zeros(numel(ox),1)]';



og=planeRotMat*og;
og=og+[0;0;targetDistance];

mirrorNormal_=normc(normc(og)-laserIncidentDirection);
angx=atand(mirrorNormal_(1,:)./mirrorNormal_(3,:))';
angy=asind(mirrorNormal_(2,:))';
angxQ=int16(angx*4/xfov*2047);
angyQ=int16(angy*4/yfov*2047);

rtd=sqrt(sum(og.^2))+sqrt(sum((og-[bl;0;0]).^2));




angXfactor = (0.25/(2^11-1));
angYfactor = (0.25/(2^11-1));
mirang = atand(projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
rangeR = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz( xfov*0.25,         0)));rangeR=rangeR(1);
rangeL = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(-xfov*0.25,         0)));rangeL=rangeL(1);
rangeT = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0         , yfov*0.25)));rangeT =rangeT (2);
rangeB = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0         ,-yfov*0.25)));rangeB=rangeB(2);




angx_ = xfov*double(angxQ)*angXfactor;
angy_ = yfov*double(angyQ)*angYfactor;
xy00 = [rangeL;rangeB];
xys = [xres;yres]./[rangeR-rangeL;rangeT-rangeB];
oXYZ = oXYZfunc(angles2xyz(angx_,angy_));
xynrm = xyz2nrmxy(oXYZ);
xynrm = rotmat*xynrm;
xy = bsxfun(@minus,xynrm,xy00);
xy    = bsxfun(@times,xy,xys);

uv=double(k*og);uv=uv(1:2,:)./uv(3,:);

plot(xy(1,:),xy(2,:),'bo',uv(1,:),uv(2,:),'go');
set(gca,'xlim',[1 xres],'ylim',[1 yres])

% quiverCmplx(arr2cmplx(uv'),arr2cmplx(xy'));
return;


ii=im2col(reshape(1:ny*nx,[ny nx]),[2 2],'sliding');
ii=ii(:,vec((1:2:ny-1)'+(0:nx-2)*ny-floor((0:nx-2)/2)*2));
pgons=arrayfun(@(i) uv(:,ii([1 2 4 3 1],i)),1:size(ii,2),'uni',0);
I=4;
im = (sum(reshape(cell2mat(cellfun(@(x) poly2mask(I*x(1,:),I*x(2,:),I*yres,I*xres),pgons,'uni',0)),I*yres,I*xres,[]),3));
im=imresize(im,1/I);
imagesc(im);
% plot(uv(1,:),uv(2,:),'ro');set(gca,'xlim',[0 w-1],'ylim',[0 h-1]);
% plotPgons(pgons,'color','r')
% end