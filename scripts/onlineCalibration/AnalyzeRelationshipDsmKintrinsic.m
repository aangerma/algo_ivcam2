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

[yy, xx] = ndgrid(1:sz(1), 1:sz(2));
in.vertices = [xx(:), yy(:), ones(prod(sz),1)] * inv(origK)';
tic
fprintf('Generating angles2pixels mapping...\n');
out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
xPixInterpolant = scatteredInterpolant(double(out.angx), double(out.angy), xx(:), 'linear');
yPixInterpolant = scatteredInterpolant(double(out.angx), double(out.angy), yy(:), 'linear');
toc

%% setting original pixels
dPix = 20;
roi = [1, 1]; % [y, x]

margin = (1-roi)/2.*sz;
x = 1+margin(2):dPix:sz(2)-margin(2);
y = 1+margin(1):dPix:sz(1)-margin(1);
[yy, xx] = ndgrid(y, x);
origPixX = xx(:);
origPixY = yy(:);

in.vertices = [origPixX, origPixY, ones(length(x)*length(y),1)] * inv(origK)';
out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
origAngX = double(out.angx);
origAngY = double(out.angy);

%% applying angular error
angX = 1.02*origAngX;
angY = origAngY;
pixX = xPixInterpolant(angX, angY);
pixY = yPixInterpolant(angX, angY);

% figure, hold on
% plot(origPixX, origPixY, 'o')
% plot(pixX, pixY, 'o')
% grid on
% 
% figure
% plot(origPixX, pixX-origPixX, 'o')
% grid on

%% optimizing K
Vmat = [in.vertices(:,[1,3]), zeros(size(in.vertices,1),2); zeros(size(in.vertices,1),2), in.vertices(:,[2,3])];
Pmat = [pixX; pixY];
Kmat = (Vmat'*Vmat)\Vmat'*Pmat;
K = [Kmat(1), 0, Kmat(2); 0, Kmat(3), Kmat(4); 0, 0, 1];









