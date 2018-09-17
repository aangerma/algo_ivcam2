function oVec = applyExpander(iVec,fovExpander)
% Recieves iVec, an Nx3 vector. A fovExpander Model.
% Applies the expantion factor to the angle between iVec and and the z-aix
% ([0,0,1]).
if isempty(fovExpander)
    oVec = iVec;
    return;
end
assert(any(size(iVec)==3));
transposed = 0;
if size(iVec,1)==3
    transposed = 1;
    iVec = iVec';
end

range = sqrt(sum(iVec.^2,2));
iVec = iVec./range;
oVec = zeros(size(iVec));
if numel(fovExpander) == 1
    oVec(:,3) = cosd(fovExpander*acosd(iVec(:,3)));
else
    oVec(:,3) = cosd(outAngleForZ(iVec(:,3),fovExpander));
end
oVec(:,1) = iVec(:,1).*sqrt((1-oVec(:,3).^2)./(iVec(:,1).^2+iVec(:,2).^2));
oVec(:,2) = iVec(:,2).*sqrt((1-oVec(:,3).^2)./(iVec(:,1).^2+iVec(:,2).^2));
oVec = oVec.*range;

if transposed
    oVec = oVec';
end
oVec(isnan(oVec)) = 0;
end

function oAng = outAngleForZ(zVec,fovExpander)
% For each z - calculate the angle. Look in the lookup table for the right
% angle and use linear interpolation.
angles = acosd(zVec);
oAng = interp1(fovExpander(:,1),fovExpander(:,2),angles);
end