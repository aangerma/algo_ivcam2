function [angx,angy] = applyZenithOnAngles(ax, ay, regs)

rotV = @(ang) [1 0 0; 0 cosd(ang) -sind(ang); 0 sind(ang) cosd(ang)];
rotH = @(ang) [cosd(ang) 0 sind(ang); 0 1 0; -sind(ang) 0 cosd(ang)];

zenithH = regs.FRMW.laserangleH;
zenithV = regs.FRMW.laserangleV;

invRotZenith = rotV(-zenithV)*rotH(-zenithH);

V = ones(length(ax),3);
V(:,1) = tand(ax);
V(:,2) = tand(ay);

V = normr(V);
V = V * invRotZenith;

angx = atand(V(:,1)./V(:,3));
angy = atand(V(:,2)./V(:,3));

end

