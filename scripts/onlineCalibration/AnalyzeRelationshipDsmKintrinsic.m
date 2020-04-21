close all
clear all
clc

%% regs definition
regs.FRMW.laserangleH = 0;
regs.FRMW.laserangleV = 0;

regs.FRMW.fovexExistenceFlag = 1;
regs.FRMW.fovexNominal = [0.0807405, 0.0030212, -0.0001276, 0.0000036];
regs.FRMW.fovexCenter = [0, 0];
regs.FRMW.fovexLensDistFlag = 0;
regs.FRMW.fovexRadialK = [0, 0, 0];
regs.FRMW.fovexTangentP = [0 0];

regs.DEST.baseline = -10;
regs.DEST.baseline2 = regs.DEST.baseline^2;

%% mapping angles to pixels
sz = [768,1024];
origK = [1024/2/tand(35), 0, 1024/2; 0, 768/2/tand(27), 768/2; 0, 0, 1]; % an "ideal" intrinsic matrix for XGA

[yPixMat, xPixMat] = ndgrid(1:sz(1), 1:sz(2));
xPix = xPixMat(:);
yPix = yPixMat(:);
verticesPix = [xPix, yPix, ones(prod(sz),1)]';
vertices = inv(origK) * verticesPix;

out = Utils.convert.SphericalToCartesian(struct('vertices',vertices), regs, 'inverse');
origAngX = out.angx;
origAngY = out.angy;
xPixInterpolant = scatteredInterpolant(origAngX, origAngY, xPix, 'linear');
yPixInterpolant = scatteredInterpolant(origAngX, origAngY, YPix, 'linear');

%% applying angular error
angX = 1.05*origAngX;
angY = origAngY;



