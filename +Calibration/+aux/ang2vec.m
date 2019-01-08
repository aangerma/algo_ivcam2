function [oXYZ] = ang2vec(angxQin,angyQin,regs,fovExpander)

%% ----STAIGHT FORWARD------
mode=regs.FRMW.mirrorMovmentMode;
xfov=regs.FRMW.xfov(mode);
yfov=regs.FRMW.yfov(mode);
projectionYshear=regs.FRMW.projectionYshear(mode);
angXfactor = single(xfov*0.25/(2^11-1));
angYfactor = single(yfov*0.25/(2^11-1));
mirang = atand(projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';

laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));

angyQ=angyQin(:);angxQ =angxQin(:);
angx = single(angxQ)*angXfactor;
angy = single(angyQ)*angYfactor;
oXYZPreExp = oXYZfunc(angles2xyz(angx,angy));
oXYZPreExp(1:2,:) = rotmat*oXYZPreExp(1:2,:);
oXYZ = Calibration.aux.applyExpander(oXYZPreExp,fovExpander);



end
