function [angx,angy] = vertices2mirrorAnglesRotMat(v, regs)

v = normr(v);

rotV = @(ang) [1 0 0; 0 cosd(ang) -sind(ang); 0 sind(ang) cosd(ang)];
rotH = @(ang) [cosd(ang) 0 sind(ang); 0 1 0; -sind(ang) 0 cosd(ang)];

zenithH = regs.FRMW.laserangleH;
zenithV = regs.FRMW.laserangleV;

invRotZenith = rotV(-zenithV)*rotH(-zenithH);

V = normr(v);
%V = V * invRotZenith;

angx = atand(V(:,1)./V(:,3));
angy = atand(V(:,2)./V(:,3));

% angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
% laserIncidentDirection = angles2xyz(double(regs.FRMW.laserangleH), double(regs.FRMW.laserangleV)+180); %+180 because the vector direction is toward the mirror
% 
% n = normr(v - repmat(laserIncidentDirection',size(v,1),1) );
% 
% angy = asind(n(:,2));
% angx = atand(n(:,1)./n(:,3));

end