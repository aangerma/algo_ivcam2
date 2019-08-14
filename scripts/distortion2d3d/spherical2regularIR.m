function regularIR = spherical2regularIR(sphericalIR, regs, tpsUndistModel)

sz = size(sphericalIR);

% generating spherical coordinates
[yg, xg] = ndgrid(0:sz(1)-1,0:sz(2)-1);

xx = (xg+0.5)*4 - double(regs.DIGG.sphericalOffset(1));
yy = yg + 1 - double(regs.DIGG.sphericalOffset(2));

xx = xx*2^10;
yy = yy*2^12;

angx = xx/double(regs.DIGG.sphericalScale(1));
angy = yy/double(regs.DIGG.sphericalScale(2));

% coordinates transformation
[ postUndistAngx, postUndistAngy ] = Calibration.Undist.applyPolyUndistAndPitchFix( angx, angy, regs );
[oXYZ] = (Calibration.aux.ang2vec(postUndistAngx, postUndistAngy, regs))';
vUnit = (Calibration.Undist.undistByTPSModel( oXYZ,tpsUndistModel));
u = vUnit(:,1)./vUnit(:,3);
v = vUnit(:,2)./vUnit(:,3);
uu = reshape(u,sz);
vv = reshape(v,sz);

% image interpolation
[xPix, yPix] = meshgrid(linspace(min(uu(:)),max(uu(:)),sz(2)), linspace(min(vv(:)),max(vv(:)),sz(1)));
F = scatteredInterpolant(uu(:), vv(:), sphericalIR(:), 'natural', 'none');
regularIR = reshape(F(xPix(:), yPix(:)), sz);


