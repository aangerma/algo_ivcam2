function [angx,angy] = vertices2ang(v, regs)

angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
laserIncidentDirection = angles2xyz(double(regs.FRMW.laserangleH), double(regs.FRMW.laserangleV)+180); %+180 because the vector direction is toward the mirror

n = normr(v - repmat(laserIncidentDirection',size(v,1),1) );

angy = asind(n(:,2));
angx = atand(n(:,1)./n(:,3));

end