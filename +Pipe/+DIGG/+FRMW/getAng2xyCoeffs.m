function newRegs = getAng2xyCoeffs(regs)
    if(regs.GNRL.rangeFinder)
        %ang2xy is disable in this mode, leave all at default, set image size
        %newRegs.GNRL.imgHsize = uint16(2);
        %newRegs.GNRL.imgVsize = uint16(1);
        newRegs.DIGG.nx(1:6) = single(0);
        newRegs.DIGG.dx2 = single(0);
        newRegs.DIGG.dx3 = single(0);
        newRegs.DIGG.dx5 = single(0);
        
        newRegs.DIGG.ny(1:6) =single(0);
        newRegs.DIGG.dy2 = single(0);
        newRegs.DIGG.dy3 = single(0);
        newRegs.DIGG.dy5 = single(0);
        
        newRegs.DIGG.angXfactor = single(0);
        newRegs.DIGG.angYfactor = single(0);
        
        newRegs.DIGG.ang2Xfactor = single(0);
        newRegs.DIGG.ang2Yfactor = single(0);
        return;
    end
    
    mode=regs.FRMW.mirrorMovmentMode; 
    xfov=regs.FRMW.xfov(mode); 
    yfov=regs.FRMW.yfov(mode); 
    projectionYshear=regs.FRMW.projectionYshear(mode); 
    
    xfactor = single(xfov*0.25/(2^11-1));
    yfactor = single(yfov*0.25/(2^11-1));
    
    newRegs.DIGG.angXfactor = xfactor*127/90;
    newRegs.DIGG.angYfactor = yfactor*127/90;
    
    newRegs.DIGG.ang2Xfactor = xfactor*254/90;
    newRegs.DIGG.ang2Yfactor = yfactor*254/90;
    
    
    mirang = atand(projectionYshear);
    rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
    
    %mirror angles to norm
    angles2xyz = @(angx,angy) [ sind(angx) cosd(angx).*sind(angy) cosd(angx).*cosd(angy)]';
    
    %norm functions
    xyz2nrmx = @(xyz) xyz(1,:)./xyz(3,:);
    xyz2nrmy = @(xyz) xyz(2,:)./xyz(3,:);
    xyz2nrmxy= @(xyz) [xyz2nrmx(xyz)  ;  xyz2nrmy(xyz)];
    
    %vector l of laser input (around (0,0,-1)):
    laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
    
    %func of direction of laser out (v- vector):   v = l+2*n*dot(n,-l)
    oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
    
    
    rangeR = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz( xfov*0.25,                   0)));rangeR=rangeR(1);
    rangeL = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(-xfov*0.25,                   0)));rangeL=rangeL(1);
    rangeT = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   , yfov*0.25)));rangeT =rangeT (2);
    rangeB = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   ,-yfov*0.25)));rangeB=rangeB(2);
    
    %ROI in pixels
    xres = uint16(int16(regs.GNRL.imgHsize)+regs.FRMW.marginL+regs.FRMW.marginR);
    yres = uint16(int16(regs.GNRL.imgVsize)+regs.FRMW.marginT+regs.FRMW.marginB);
    newRegs.FRMW.xres = xres;
    newRegs.FRMW.yres = yres;

    % guard bands in pixels (originally in %)
    guardXinc = regs.FRMW.guardBandH*single(xres);
    guardYinc = regs.FRMW.guardBandV*single(yres);
    
    % pixel res in the entire resterised area
    xresN = single(xres) + guardXinc*2;
    yresN = single(yres) + guardYinc*2;
    
    %total mrgins: ROI_margins+guard_bands (in pixels)
    % marginRN = regs.FRMW.marginR + guardXinc;
    marginLN = single(regs.FRMW.marginL) + guardXinc;
    marginTN = single(regs.FRMW.marginB) + guardYinc;
    % marginBN = regs.FRMW.marginB + guardYinc;
    
        
    ysign = 1;
    if(regs.FRMW.yflip)
        ysign=-1;
    end
    xsign = 1;
    if(regs.FRMW.xR2L)
        xsign=-1;
    end
    
    
    k0 = yresN*cosd(regs.FRMW.laserangleH);
    k1 = xresN*cosd(regs.FRMW.laserangleH);
    k2 = sqrt(projectionYshear.*projectionYshear+1.0);
    k3 = cosd(regs.FRMW.laserangleH).*sind(regs.FRMW.laserangleV).*k2;
    k4 = cosd(regs.FRMW.laserangleH).*cosd(regs.FRMW.laserangleV).*k2;
    k5 = sind(regs.FRMW.laserangleH)*k2;
    k6 = rangeR-rangeL;
    k7 = rangeB-rangeT;
    k8 = (rangeB.*yresN-k7*marginTN);
    k9 = (rangeL.*xresN+k6*marginLN);
    
    
    newRegs.DIGG.nx(6) = single(  k1*sind(regs.FRMW.laserangleV)*projectionYshear                                                                 );
    newRegs.DIGG.nx(1) = single( -xresN*sind(regs.FRMW.laserangleH)                                                                                         );
    newRegs.DIGG.nx(2) = single( -k9*k4 +regs.FRMW.xoffset*k6*k4                                                                                                                    );
    newRegs.DIGG.nx(3) = single( ((k1*cosd(regs.FRMW.laserangleV)+(rangeL*xresN+k6*marginLN)*k5)  +regs.FRMW.xoffset*(-k6*k5))*xsign                                                          );
    newRegs.DIGG.nx(4) = single( (-xresN*sind(regs.FRMW.laserangleH)*projectionYshear+k1*sind(regs.FRMW.laserangleV))*ysign*xsign                               );
    newRegs.DIGG.nx(5) = single(  (k1*cosd(regs.FRMW.laserangleV)*projectionYshear-k9*k3 + regs.FRMW.xoffset*k6*k3 )*ysign                                                   );
    newRegs.DIGG.dx2 = single(   k6*k4                                                                                                                    );
    newRegs.DIGG.dx3 = single(  -k6*k5*xsign                                                                                                                    );
    newRegs.DIGG.dx5 = single(   k6*k3*ysign                                                                                                                    );
    newRegs.DIGG.ny(6) = single( k0*sind(regs.FRMW.laserangleV)                                                                                             );
    newRegs.DIGG.ny(1) = single( yresN*sind(regs.FRMW.laserangleH)*projectionYshear                                                               );
    newRegs.DIGG.ny(2) = single( - k8*k4   +regs.FRMW.yoffset*(-k7*k4)                                                                                                                 );
    newRegs.DIGG.ny(3) = single( ( k8*k5-k0.*cosd(regs.FRMW.laserangleV)*projectionYshear   +regs.FRMW.yoffset* ( k7*k5 ) )*xsign                                                     );
    newRegs.DIGG.ny(4) = single( -(yresN*(sind(regs.FRMW.laserangleH)+projectionYshear.*cosd(regs.FRMW.laserangleH).*sind(regs.FRMW.laserangleV)))*ysign*xsign);
    newRegs.DIGG.ny(5) = single(  ((k0.*cosd(regs.FRMW.laserangleV)-k8*k3)    +regs.FRMW.yoffset*   (-k7*k3   ))*ysign                                                                            );
    newRegs.DIGG.dy2 = single(  -k7*k4                                                                                                                    );
    newRegs.DIGG.dy3 = single(   k7*k5*xsign                                                                                                                    );
    newRegs.DIGG.dy5 = single(  -k7*k3*ysign                                                                                                                    );
    
end