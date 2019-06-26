function [ angxDist, angyDist ] = inversePolyUndistAndPitchFix( angx, angy, regs )
% Applies inverse undistortion accounting for MC errors in reported angles.
%   Input & output angles are all in DSM units.

% [ preUndistAngx ] = Calibration.Undist.inversePolyUndist( angx,regs );
% preUndistAngy = angy - preUndistAngx/2047*regs.FRMW.pitchFixFactor;

% Generate LUT
angGrid = -2100:10:2100; % [DSM units] resolution suffices for errors less than 8e-4
[angxGridOut, angyGridOut] = meshgrid(angGrid, angGrid);
[angxGridIn, angyGridIn] = Calibration.Undist.applyPolyUndistAndPitchFix(angxGridOut(:), angyGridOut(:), regs);
xInterpolant = scatteredInterpolant(double(angxGridIn), double(angyGridIn), angxGridOut(:), 'linear');
yInterpolant = scatteredInterpolant(double(angxGridIn), double(angyGridIn), angyGridOut(:), 'linear');

% Use LUT
angxIn = double(angx(:));
angyIn = double(angy(:));
angxDist = reshape(single(xInterpolant(angxIn, angyIn)), size(angx));
angyDist = reshape(single(yInterpolant(angxIn, angyIn)), size(angy));

end