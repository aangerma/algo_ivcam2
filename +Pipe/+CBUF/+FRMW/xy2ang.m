function [angx,angy] = xy2ang(x,y,regs)
%{
[yg,xg]=ndgrid(0:single(regs.GNRL.imgVsize)-1,0:single(regs.GNRL.imgHsize)-1);
[ax,ay]=Pipe.CBUF.FRMW.xy2ang(xg,yg,regs);
[~,~,xg_,yg_]=Pipe.DIGG.ang2xy(ax,ay,regs,Logger(),[]);
subplot(121);imagesc(abs(xg_-xg));colorbar;axis image;subplot(122);imagesc(abs(yg_-yg));colorbar;axis image
%}
x=single(x);
y=single(y);
angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
mirang = atand(regs.FRMW.projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
invrotmat = rotmat^-1;%[cosd(mirang) -sind(mirang);sind(mirang) cosd(mirang)];
angles2xyz = @(angx,angy) [ sind(angx) cosd(angx).*sind(angy) cosd(angx).*cosd(angy)]';
marginT = regs.FRMW.marginT;
marginL = regs.FRMW.marginL;
xyz2nrmx = @(xyz) xyz(1,:)./xyz(3,:);
xyz2nrmy = @(xyz) xyz(2,:)./xyz(3,:);
xyz2nrmxy= @(xyz) [xyz2nrmx(xyz)  ;  xyz2nrmy(xyz)];
laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
rangeR = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz( regs.FRMW.xfov*0.25,                   0)));rangeR=rangeR(1);
rangeL = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(-regs.FRMW.xfov*0.25,                   0)));rangeL=rangeL(1);
rangeT = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   , regs.FRMW.yfov*0.25)));rangeT =rangeT (2);
rangeB = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   ,-regs.FRMW.yfov*0.25)));rangeB=rangeB(2);

guardXinc = regs.FRMW.guardBandH*single(regs.FRMW.xres);
guardYinc = regs.FRMW.guardBandV*single(regs.FRMW.yres);

xresN = single(regs.FRMW.xres) + guardXinc*2;
yresN = single(regs.FRMW.yres) + guardYinc*2;

xys = [xresN;yresN]./[rangeR-rangeL;rangeT-rangeB];
xy00 = [rangeL;rangeB];


xy = [x(:)+double(marginL+int16(guardXinc)) y(:)+double(marginT+int16(guardYinc))];
xy = bsxfun(@rdivide,xy,xys');
xy = bsxfun(@plus,xy,xy00');
xynrm = invrotmat*xy';


v = normr([xynrm' ones(size(xynrm,2),1)]);
n = normr(v - repmat(laserIncidentDirection',size(v,1),1) );
angxQ = asind(n(:,1));
angyQ = atand(n(:,2)./n(:,3));

angy = reshape(single(angyQ)/angYfactor,size(y));
angx=  reshape(single(angxQ)/angXfactor,size(y));
end