function [angx,angy] = vec2ang(vec,regs)
%{
Takes v, a Nx3 matrix, each V represents the direction of the output beam.
Returns the angx,angy of the mirror.
%}
angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';

laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror

v = normr(vec);
n = normr(v - repmat(laserIncidentDirection',size(v,1),1) );

angyQ = asind(n(:,2));
angxQ = atand(n(:,1)./n(:,3));


angy = single(angyQ)/angYfactor;
angx = single(angxQ)/angXfactor;
end
