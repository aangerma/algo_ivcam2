function [guardband] = guardbandFromPixel(xIm,yIm,regs,axis)
%GUARDBANDFROMPIXEL gets the x,y index of the pixel and returnes the
%guardband value that will get it to index 1 or (res-1), depends on the
%proximity. Axis is either 'H' or 'V'

assert(axis == 'V' || axis == 'H', 'axis should be in [''H'',''V'']')
[angx,angy]=Pipe.CBUF.FRMW.xy2ang(xIm,yIm,regs);

bestDiff = inf;
guardband = 0;
for gbnd = 0:0.0025:0.15
    [x,y] = xyForGuardband(angx,angy,gbnd,regs,axis);   
    if axis == 'H'
       source = x; 
       target = single(0 + uint16(angx>0)*(regs.FRMW.xres));
    else
       source = y; 
       target = single(0 + uint16(angy>0)*(regs.FRMW.yres));
    end
    
    if abs(source-target)<bestDiff
       guardband = gbnd;
       bestDiff = abs(source-target);
    end
end


end

function [x,y] = xyForGuardband(angx,angy,gbnd,regs,axis)

angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
mirang = atand(regs.FRMW.projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
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

if axis == 'H'
    guardXinc = gbnd*single(regs.FRMW.xres);
    guardYinc = regs.FRMW.guardBandV*single(regs.FRMW.yres);
else
    guardXinc = regs.FRMW.guardBandH*single(regs.FRMW.xres);
    guardYinc = gbnd*single(regs.FRMW.yres);
end


xresN = single(regs.FRMW.xres) + guardXinc*2;
yresN = single(regs.FRMW.yres) + guardYinc*2;


angx = single(angx)*angXfactor;
angy = single(angy)*angYfactor;
xy00 = [rangeL;rangeB];
xys = [xresN;yresN]./[rangeR-rangeL;rangeT-rangeB];
oXYZ = oXYZfunc(angles2xyz(angx,angy));
xynrm = [xyz2nrmx(oXYZ);xyz2nrmy(oXYZ)];
xynrm = rotmat*xynrm;
xy = bsxfun(@minus,xynrm,xy00);
xy = bsxfun(@times,xy,xys);
xy = bsxfun(@minus,xy,double([marginL+int16(guardXinc);marginT+int16(guardYinc)]));
x = xy(1);y=xy(2);
end
