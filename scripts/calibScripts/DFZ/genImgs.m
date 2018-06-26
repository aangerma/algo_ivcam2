 function [im,rxy,k]=genImgs(regs,targetVector)
% clear;
% regs.FRMW.xfov=72;
% regs.FRMW.yfov=56;
% regs.FRMW.xres=640;
% regs.FRMW.yres=480;
% regs.DEST.baseline=30;%mm
% regs.FRMW.projectionYshear=0;
% targetVector = 500*normc([0;0;1]);



regs.FRMW.laserangleH=1.5;
regs.FRMW.laserangleV=1.5;

%%
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx) sind(angy) cosd(angx).*cosd(angy)]';
laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
xyz2nrmxy= @(xyz) xyz(1:2,:)./xyz(3,:);
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
% arr2cmplx=@(x) iff(size(x,1)==2,x(1,:)+1j*x(2,:),x(:,1)+1j*x(:,2));


p=Calibration.getTargetParams();
ny=p.cornersY+2;
nx=p.cornersX+2;
[oy,ox]=ndgrid(linspace(-1,1,ny)*(ny-1)*p.mmPerUnitY/2,linspace(-1,1,nx)*(nx-1)*p.mmPerUnitY/2);
og = [ox(:) oy(:) zeros(numel(ox),1)]';


planeRotMat=rotationVectorToMatrix(normc(cross(normc(targetVector),[0;0;1])+[0;0;eps])*acos(normc(targetVector)'*[0;0;1]));
og=planeRotMat*og;
og=og+[0;0;norm(targetVector)];

mirrorNormal_=normc(normc(og)-laserIncidentDirection);
angx=atand(mirrorNormal_(1,:)./mirrorNormal_(3,:))';
angy=asind(mirrorNormal_(2,:))';
angxQ=int16(angx*4/regs.FRMW.xfov*2047);
angyQ=int16(angy*4/regs.FRMW.yfov*2047);

rtd=sqrt(sum(og.^2))+sqrt(sum((og-[double(regs.DEST.baseline);0;0]).^2));
rxy=[rtd*8;angxQ';angyQ'];



angXfactor = (0.25/(2^11-1));
angYfactor = (0.25/(2^11-1));
mirang = atand(regs.FRMW.projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
rangeR = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz( regs.FRMW.xfov*0.25,         0)));rangeR=rangeR(1);
rangeL = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(-regs.FRMW.xfov*0.25,         0)));rangeL=rangeL(1);
rangeT = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0         , regs.FRMW.yfov*0.25)));rangeT =rangeT (2);
rangeB = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0         ,-regs.FRMW.yfov*0.25)));rangeB=rangeB(2);

p2axa = (rangeR-rangeL)/ single(regs.FRMW.xres-1);
p2axb = rangeL    ;
p2aya = (rangeT-rangeB)/ single(regs.FRMW.yres-1);
p2ayb = rangeB   ;

% k=[
% 0.5*(regs.FRMW.xres)/tand(regs.FRMW.xfov/2) 0                      (regs.FRMW.xres)/2;
% 0                      0.5*(regs.FRMW.yres)/tand(regs.FRMW.yfov/2) (regs.FRMW.yres)/2;
% 0                      0                       1
% ];

k=pinv([
   p2axa 0      p2axb;
   0     p2aya  p2ayb;
   0     0      1]);

angx_ = regs.FRMW.xfov*double(angxQ)*angXfactor;
angy_ = regs.FRMW.yfov*double(angyQ)*angYfactor;
xy00 = [rangeL;rangeB];
xys = single([regs.FRMW.xres-1;regs.FRMW.yres-1])./[rangeR-rangeL;rangeT-rangeB];
oXYZ = oXYZfunc(angles2xyz(angx_,angy_));
xynrm = xyz2nrmxy(oXYZ);
xynrm = rotmat*xynrm;
xy = bsxfun(@minus,xynrm,xy00);
xy    = bsxfun(@times,xy,xys);

%{
%% verify that ang2xy is the same as using k matrix
uv=double(k*og);uv=uv(1:2,:)./uv(3,:);
plot(xy(1,:),xy(2,:),'bo',uv(1,:),uv(2,:),'go');
set(gca,'xlim',[1 regs.FRMW.xres],'ylim',[1 regs.FRMW.yres])
rms(sqrt(sum(uv-xy).^2))
%}

ii=im2col(reshape(1:ny*nx,[ny nx]),[2 2],'sliding');
ii=ii(:,vec((1:2:ny-1)'+(0:nx-2)*ny-floor((0:nx-2)/2)*2));
pgons=arrayfun(@(i) double(xy(:,ii([1 2 4 3 1],i))),1:size(ii,2),'uni',0);
margin=xy(:,[1 ny nx*ny (nx-1)*ny+1 1 ]);
margin=[(margin-mean(margin,2))*0.95 (margin-mean(margin,2))*1.05]+mean(margin,2);
 pgons{end+1}=double(margin);


I=4;
im = double(any(reshape(cell2mat(cellfun(@(x) poly2mask(I*x(1,:),I*x(2,:),I*double(regs.FRMW.yres),I*double(regs.FRMW.xres)),pgons,'uni',0)),I*regs.FRMW.yres,I*regs.FRMW.xres,[]),3));
im=imresize(im,1/I);

% plot(uv(1,:),uv(2,:),'ro');set(gca,'xlim',[0 w-1],'ylim',[0 h-1]);
% plotPgons(pgons,'color','r')
 end