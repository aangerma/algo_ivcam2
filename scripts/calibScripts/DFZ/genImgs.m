 function [im,rxy,k]=genImgs(regs,targetVector,tau)
% clear;
% regs.FRMW.xfov=72;
% regs.FRMW.yfov=56;
% regs.FRMW.xres=640;
% regs.FRMW.yres=480;
% regs.DEST.baseline=30;%mm
% regs.FRMW.projectionYshear=0;
% targetVector = 500*normc([0;0;1]);



%%
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx) sind(angy) cosd(angx).*cosd(angy)]';
laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
xyz2nrmxy= @(xyz) xyz(1:2,:)./xyz(3,:);
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
% arr2cmplx=@(x) iff(size(x,1)==2,x(1,:)+1j*x(2,:),x(:,1)+1j*x(:,2));

angXfactor = regs.FRMW.xfov*(0.25/(2^11-1));
angYfactor = regs.FRMW.yfov*(0.25/(2^11-1));


% sqMM=30;
% ny=9+2;
% nx=13+2;
% [oy,ox]=ndgrid(linspace(-1,1,ny)*(ny-1)*sqMM/2,linspace(-1,1,nx)*(nx-1)*sqMM/2);
% og = [ox(:) oy(:) zeros(numel(ox),1)]';



%%

sqMM=30;

n=5;
l=(n-1)*3;
[oy,ox]=ndgrid(linspace(0,1,n)*(n-1)*sqMM,linspace(0,1,n)*(n-1)*sqMM);
og_ = [ox(:) oy(:) zeros(numel(ox),1)]';
og_=[og_ [1 0 0;1 1 0;0 1 0;0 2 0;2 2 0;2 1 0;2 0 0]'*sqMM/3+[0;0;1e-3]];
og_=[og_ [l-1 0 0;l-1 1 0;l 1 0;l 2 0;l-2 2 0;l-2 1 0;l-2 0 0]'*sqMM/3+[0;0;1e-3]];
og_=[og_ [1 l 0;1 l-1 0;0 l-1 0;0 l-2 0;2 l-2 0;2 l-1 0;2 l 0]'*sqMM/3+[0;0;1e-3]];
og_=[og_ [0 0 0; 0 l 0 ; l l 0 ; l 0 0]'*sqMM/3*1.1-[0;0;1e-1]];

s2i = @(y,x) sub2ind([n,n],vec(oy(1:end-1,1:end-1)/sqMM+1)+y,vec(ox(1:end-1,1:end-1)/sqMM+1)+x);
tri=[s2i(0,0) s2i(1,0) s2i(1,1);s2i(0,0) s2i(1,1) s2i(0,1)];
tri=[tri;[1 7 6;1 6 2;3 4 5;3 5 6]+size(ox(:),1)];
tri=[tri;[1 7 6;1 6 2;3 4 5;3 5 6]+7+size(ox(:),1)];
tri=[tri;[1 7 6;1 6 2;3 4 5;3 5 6]+14+size(ox(:),1)];
 tri=[tri;[1 2 3;1 3 4]+21+size(ox(:),1)];
tri=[tri;tri+size(og_,2);tri+2*size(og_,2)];
og_=[og_ og_([3 2 1],:) og_([1 3 2],:)];
a=[repmat((-1).^(s2i(0,0)),2,1);ones(4,1);-1*ones(8,1);-1*ones(2,1)];
a=repmat(a,3,1);
hh=trisurf(tri,og_(1,:),og_(2,:),og_(3,:),a);set(hh,'edgecolor','none');axis equal;view(144,33);
%%



planeRotMat=rotationVectorToMatrix(normc(cross(normc(targetVector),[0;0;1])+[0;0;eps])*acos(normc(targetVector)'*[0;0;1]));
og=planeRotMat*og;
og=og+[0;0;norm(targetVector)];

mirrorNormal_=normc(normc(og)-laserIncidentDirection);
angx=atand(mirrorNormal_(1,:)./mirrorNormal_(3,:))';
angy=asind(mirrorNormal_(2,:))';

%%%%NO  QUANTIZATION
angxQ=(angx/angXfactor);
angyQ=(angy/angYfactor);

% angxQ=int16(angx/angXfactor);
% angyQ=int16(angy/angYfactor);


rtd=sqrt(sum(og.^2))+sqrt(sum((og-[double(regs.DEST.baseline);0;0]).^2))+tau;
rxy=[rtd;double(angxQ');double(angyQ')];
% rxy=reshape(rxy,3,ny,nx);
% rxy=rxy(:,2:end-1,2:end-1);
% rxy=reshape(rxy,3,[]);
% 


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

angx_ = double(angxQ)*angXfactor;
angy_ = double(angyQ)*angYfactor;
xy00 = [rangeL;rangeB];
xys = single([regs.FRMW.xres-1;regs.FRMW.yres-1])./[rangeR-rangeL;rangeT-rangeB];
oXYZ = oXYZfunc(angles2xyz(angx_,angy_));
xynrm = xyz2nrmxy(oXYZ);
xynrm = rotmat*xynrm;
xy = bsxfun(@minus,xynrm,xy00);
xy    = bsxfun(@times,xy,xys);

k=pinv([
   p2axa 0      p2axb;
   0     p2aya  p2ayb;
   0     0      1]);
%{
%% verify that ang2xy is the same as using k matrix
uv=double(k*og);uv=uv(1:2,:)./uv(3,:);
plot(xy(1,:),xy(2,:),'bo',uv(1,:),uv(2,:),'go');
set(gca,'xlim',[1 regs.FRMW.xres],'ylim',[1 regs.FRMW.yres])
rms(sqrt(sum(uv-xy).^2))
%}

ii=im2col(reshape(1:n*n,[n n]),[2 2],'sliding');
ii=ii(:,vec((1:2:n-1)'+(0:n-2)*n-floor((0:n-2)/2)*2));
pgons=arrayfun(@(i) double(xy(:,ii([1 2 4 3 1],i))),1:size(ii,2),'uni',0);
margin=xy(:,[1 n n*n (n-1)*n+1 1 ]);
margin=[(margin-mean(margin,2))*0.95 (margin-mean(margin,2))*1.09]+mean(margin,2);
 pgons{end+1}=double(margin);


I=4;
im = double(any(reshape(cell2mat(cellfun(@(x) poly2mask(I*x(1,:),I*x(2,:),I*double(regs.FRMW.yres),I*double(regs.FRMW.xres)),pgons,'uni',0)),I*regs.FRMW.yres,I*regs.FRMW.xres,[]),3));
im=imresize(im,1/I);

% plot(uv(1,:),uv(2,:),'ro');set(gca,'xlim',[0 w-1],'ylim',[0 h-1]);
% plotPgons(pgons,'color','r')
 end