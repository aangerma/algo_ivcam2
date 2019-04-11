function [angx,angy] = vec2ang(vorig,regs,fovExpander)
%{Receives a 3d unit vector v and calculates the corresponding received angx angy.%}
if numel(size(vorig)) == 3
    v = reshape(vorig,[size(vorig,1)*size(vorig,2),3]);
else
    v = vorig;
end
angXfactor = single(regs.FRMW.xfov(1)*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov(1)*0.25/(2^11-1));
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror

if ~isempty(fovExpander)
    v = Calibration.aux.applyExpander(v,fliplr(fovExpander));
end
n = normr(v - repmat(laserIncidentDirection',size(v,1),1) );

angyQ = asind(n(:,2));
angxQ = atand(n(:,1)./n(:,3));


angy = single(angyQ)/angYfactor;
angx = single(angxQ)/angXfactor;
if numel(size(vorig)) == 3
    angy = reshape(angy,size(vorig,1),size(vorig,2));
    angx = reshape(angx,size(vorig,1),size(vorig,2));
end
end