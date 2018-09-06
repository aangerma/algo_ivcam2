function [xF,yF] = ang2xySF(angxQin,angyQin,regs,fovExpander,useFix)
%{
A Straight forward calculation of ang2xy.
If useFix is False, it performs the transformation as in the version that's
in the Pipe (bugged). Otherwise, it performs the calculation correctly.

fovExpander either an [M,2] array with M
input angle bins and the relevant expansion factor, or a single value for
all angles.
%}
%% ----STAIGHT FORWARD------

angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
mirang = atand(regs.FRMW.projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
if ~useFix
    angles2xyz = @(angx,angy) [             sind(angx) cosd(angx).*sind(angy) cosd(angy).*cosd(angx)]';
else
    angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
end
marginB = regs.FRMW.marginB;
marginT = regs.FRMW.marginT;
marginR = regs.FRMW.marginR;
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

angyQ=angyQin(:);angxQ =angxQin(:);
angx = single(angxQ)*angXfactor;
angy = single(angyQ)*angYfactor;
xy00 = [rangeL;rangeB];
xys = [xresN;yresN]./[rangeR-rangeL;rangeT-rangeB];% xys = [xresN-1;yresN-1]./[rangeR-rangeL;rangeT-rangeB];
oXYZ = applyExpander(oXYZfunc(angles2xyz(angx,angy)),fovExpander);
xynrm = [xyz2nrmx(oXYZ);xyz2nrmy(oXYZ)];
xynrm = rotmat*xynrm;
xy = bsxfun(@minus,xynrm,xy00);
xy    = bsxfun(@times,xy,xys);
xy = bsxfun(@minus,xy,double([marginL+int16(guardXinc);marginT+int16(guardYinc)]));
% plot(xy(1,:),xy(2,:));
% rectangle('position',[0 0 double(regs.GNRL.imgHsize) double(regs.GNRL.imgVsize)])
xF = reshape(xy(1,:),size(angxQin));
yF = reshape(xy(2,:),size(angyQin));
end

