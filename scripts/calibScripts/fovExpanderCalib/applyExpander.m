function oVec = applyExpander(iVec,fovExpander)
% Recieves iVec, an Nx3 vector. A fovExpander Model.
% Applies the expantion factor to the angle between iVec and and the z-aix
% ([0,0,1]).
assert(size(iVec,2)==3);
oVec = zeros(size(iVec));
if numel(fovExpander) == 1
    oVec(:,3) = cosd(fovExpander*acosd(iVec(:,3)));
else
    outAngleForZ(iVec(:,3),fovExpander);
end
oVec(:,1) = iVec(:,1).*sqrt((1-oVec(:,3).^2)./(iVec(:,1).^2+iVec(:,2).^2));
oVec(:,2) = iVec(:,2).*sqrt((1-oVec(:,3).^2)./(iVec(:,1).^2+iVec(:,2).^2));

end

function oAng = outAngleForZ(zVec,fovExpander)
% For each z - calculate the angle. Look in the lookup table for the right
% angle and use linear interpolation.
angles = acosd(zVec);
oAng = interp1(fovExpander(:,1),fovExpander(:,2),angles);
end