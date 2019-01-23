function regsOut = trigoCalcs(regs)
mode=regs.FRMW.mirrorMovmentMode;
xfov=regs.FRMW.xfov(mode);
yfov=regs.FRMW.yfov(mode);
xfovPix = xfov;
yfovPix = yfov;

if(regs.DIGG.undistBypass==0)
    xfovPix = xfovPix*regs.FRMW.undistXfovFactor;
    yfovPix = yfovPix*regs.FRMW.undistYfovFactor;
end

[regsOut.DEST.p2axa,regsOut.DEST.p2axb,regsOut.DEST.p2aya,regsOut.DEST.p2ayb] = p2aCalc(regs,xfovPix,yfovPix,0);
if(regs.GNRL.rangeFinder)
    regsOut.DEST.p2aya = single(0);
    regsOut.DEST.p2ayb  = single(0);
end

% Calculate K matrix. Note - users image is rotated by 180 degrees in
% respect to our internal representation.
[p2axa,p2axb,p2aya,p2ayb] = p2aCalc(regs,xfovPix,yfovPix,1);
Kinv=[p2axa            0                   p2axb;
    0                p2aya               p2ayb;
    0                0                   1    ];

K=pinv(Kinv);
K=abs(K); % Make it so the K matrix is positive. This way the orientation of the cloud point is identical to DS. 
regsOut.CBUF.spare=typecast(K([1 4 7 2 5 8 3 6]),'uint32');
end

function [p2axa,p2axb,p2aya,p2ayb] = p2aCalc(regs,xfov,yfov,rot180)
%{
Calculates tanx and tany for the four sides of the image.
if rot90 is true,calculate the coefficients for an outside image - which is
the matlab image rotated by 180 degrees. fliplr(flipud()).
%}
%% ----STAIGHT FORWARD------
mode=regs.FRMW.mirrorMovmentMode;

projectionYshear=regs.FRMW.projectionYshear(mode);

mirang = atand(projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];

angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';

xyz2nrmx = @(xyz) xyz(1,:)./xyz(3,:);
xyz2nrmy = @(xyz) xyz(2,:)./xyz(3,:);
xyz2nrmxy= @(xyz) [xyz2nrmx(xyz)  ;  xyz2nrmy(xyz)];
laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
rangeR = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz( xfov*0.25,                   0)));rangeR=rangeR(1);
rangeL = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(-xfov*0.25,                   0)));rangeL=rangeL(1);
rangeT = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   , yfov*0.25)));rangeT =rangeT (2);
rangeB = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   ,-yfov*0.25)));rangeB=rangeB(2);
if ~rot180
    p2axa = (rangeR-rangeL)/ single(regs.FRMW.xres-1);
    p2axb = rangeL  + single(regs.FRMW.marginL) / single(regs.FRMW.xres-1)*(rangeR-rangeL) ;
    p2aya = (rangeT-rangeB)/ single(regs.FRMW.yres-1);
    p2ayb = rangeB  + single(regs.FRMW.marginB) / single(regs.FRMW.yres-1)*(rangeT-rangeB) ;
else
    p2axa = (rangeR-rangeL)/ single(regs.FRMW.xres-1);
    p2axb = -rangeR  + single(regs.FRMW.marginR) / single(regs.FRMW.xres-1)*(rangeR-rangeL) ;
    p2aya = -(rangeT-rangeB)/ single(regs.FRMW.yres-1);
    p2ayb = rangeT  - single(regs.FRMW.marginT) / single(regs.FRMW.yres-1)*(rangeT-rangeB) ;
end
end
