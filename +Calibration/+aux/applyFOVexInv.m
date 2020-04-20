function outVec = applyFOVexInv( inVec, regs )
% Applies inverse distortion accounting for virtual mirror representation due to FOVex.

if ~regs.FRMW.fovexExistenceFlag % unit without FOVex
    outVec = inVec;
    return
end

% Preparations
assert(any(size(inVec)==3));
transposed = 0;
if (size(inVec,1)==3) % applyFOVexInv processes row vectors
    transposed = 1;
    inVec = inVec';
end
range = sqrt(sum(inVec.^2,2));
inVec = inVec./range; % normalizing to ensure unit direction vectors

% Auxiliary
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)];
xyz2angles = @(v) [ atan2d(v(:,1),v(:,3))  asind(v(:,2))];

% Generate LUT
maxFOVx = 65; % [deg]
maxFOVy = 51; % [deg]
nPtsX = 131; nPtsY = 103; % 1[deg] LUT resolution - leads to errors up to ~1[mdeg]
[angxGridOut, angyGridOut] = meshgrid(linspace(-maxFOVx/2, maxFOVx/2, nPtsX), linspace(-maxFOVy/2, maxFOVy/2, nPtsY));
vecGridOut = angles2xyz(angxGridOut(:), angyGridOut(:));
vecGridIn = Calibration.aux.applyFOVex(vecGridOut, regs);
angxyGridIn = double(xyz2angles(vecGridIn));
xInterpolant = scatteredInterpolant(angxyGridIn(:,1), angxyGridIn(:,2), angxGridOut(:), 'linear');
yInterpolant = scatteredInterpolant(angxyGridIn(:,1), angxyGridIn(:,2), angyGridOut(:), 'linear');

% Use LUT
angxyIn = double(xyz2angles(inVec));
angxOut = single(xInterpolant(angxyIn(:,1), angxyIn(:,2)));
angyOut = single(yInterpolant(angxyIn(:,1), angxyIn(:,2)));
outVec = angles2xyz(angxOut(:), angyOut(:));

% Aligning with original representation
outVec = outVec.*range;
if transposed
    outVec = outVec';
end
outVec(isnan(outVec)) = 0;
