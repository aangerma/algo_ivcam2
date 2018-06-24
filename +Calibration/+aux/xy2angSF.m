function [angx,angy] = xy2angSF(x,y,regs,useFix)
%{
A Straight forward calculation of xy2ang.
Performs an inverse to ang2xy function. If useFix is False, it invereses
the bugged version, otherwise it is inversing as if ang2xy is not bugged.
%}
x=single(x);
y=single(y);
angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
mirang = atand(regs.FRMW.projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
invrotmat = rotmat^-1;%[cosd(mirang) -sind(mirang);sind(mirang) cosd(mirang)];
if ~useFix
    angles2xyz = @(angx,angy) [             sind(angx) cosd(angx).*sind(angy) cosd(angy).*cosd(angx)]';
else
    angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
end

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

gaurdXinc = regs.FRMW.gaurdBandH*single(regs.FRMW.xres);
gaurdYinc = regs.FRMW.gaurdBandV*single(regs.FRMW.yres);

xresN = single(regs.FRMW.xres) + gaurdXinc*2;
yresN = single(regs.FRMW.yres) + gaurdYinc*2;

xys = [xresN;yresN]./[rangeR-rangeL;rangeT-rangeB];
xy00 = [rangeL;rangeB];


xy = [x(:)+double(marginL+int16(gaurdXinc)) y(:)+double(marginT+int16(gaurdYinc))];
xy = bsxfun(@rdivide,xy,xys');
xy = bsxfun(@plus,xy,xy00');
xynrm = invrotmat*xy';


v = normr([xynrm' ones(size(xynrm,2),1)]);
n = normr(v - repmat(laserIncidentDirection',size(v,1),1) );

if ~useFix
    angxQ = asind(n(:,1));
    angyQ = atand(n(:,2)./n(:,3));
else
    angyQ = asind(n(:,2));
    angxQ = atand(n(:,1)./n(:,3));
end

angy = reshape(single(angyQ)/angYfactor,size(y));
angx=  reshape(single(angxQ)/angXfactor,size(y));
end