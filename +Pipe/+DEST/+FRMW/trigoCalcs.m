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

[regsOut.DEST.p2axa,regsOut.DEST.p2axb,regsOut.DEST.p2aya,regsOut.DEST.p2ayb] = p2aCalc(regs,xfovPix,yfovPix);
KinvRaw=[regsOut.DEST.p2axa            0                   regsOut.DEST.p2axb;
    0                regsOut.DEST.p2aya               regsOut.DEST.p2ayb;
    0                0                   1    ];
KRaw=inv(KinvRaw);
KRaw=abs(KRaw); % Make it so the K matrix is positive. This way the orientation of the cloud point is identical to DS.
regsOut.FRMW.kRaw=typecast(KRaw([1 4 7 2 5 8 3 6]),'uint32');

if(regs.GNRL.rangeFinder)
    regsOut.DEST.p2aya = single(0);
    regsOut.DEST.p2ayb  = single(0);
end

% Calculate K matrix. Note - users image is rotated by 180 degrees in
% respect to our internal representation.
Kworld=KRaw;
Kworld(1,3)=single(regs.GNRL.imgHsize)-1-KRaw(1,3);
Kworld(2,3)=single(regs.GNRL.imgVsize)-1-KRaw(2,3);

regsOut.CBUF.spare=typecast(Kworld([1 4 7 2 5 8 3 6]),'uint32');
regsOut.FRMW.kWorld=typecast(Kworld([1 4 7 2 5 8 3 6]),'uint32');

%% zero order location
%ZOLOC calculates the location of the ZO pixel (in the users rectified
%image).
regs = Firmware.mergeRegs(regs,regsOut);

[xZOraw,yZOraw] = Calibration.aux.ang2xySF(0,0,regs,[],1); % ZO location
regsOut.FRMW.zoRawCol= uint16(floor(xZOraw));
regsOut.FRMW.zoRawRow= uint16(floor(yZOraw));

regsOut.FRMW.zoWorldCol = regs.GNRL.imgHsize - uint16(floor(xZOraw));
regsOut.FRMW.zoWorldRow  =regs.GNRL.imgVsize - uint16(floor(yZOraw));

end

function [p2axa,p2axb,p2aya,p2ayb] = p2aCalc(regs,xfov,yfov)
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

p2axa = (rangeR-rangeL)/ single(regs.FRMW.xres-1);
p2axb = rangeL  + single(regs.FRMW.marginL) / single(regs.FRMW.xres-1)*(rangeR-rangeL) ;
p2aya = (rangeT-rangeB)/ single(regs.FRMW.yres-1);
p2ayb = rangeB  + single(regs.FRMW.marginB) / single(regs.FRMW.yres-1)*(rangeT-rangeB) ;

end
