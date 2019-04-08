function [res] = matchPZRs(sphCap, sphRegs, wCap, verbose, fileName)

if ~exist('verbose','var')
    verbose = false;
end

if ~exist('fileName','var')
    fileName = '';
end

irSph = rot90(sphCap.ir,2);
%irSph = sphCap.ir;
irSph = fillHolesMM(irSph);

[ptsSph, gridSizeSph] = Validation.aux.findCheckerboard(irSph);
if (verbose)
    figure; imagesc(irSph); hold on; plot(ptsSph(:,1),ptsSph(:,2),'+r');
    title('Spherical image with PZR data');
end

wFrame = wCap.frame;
%wFrame.i = rot90(wFrame.i,2);
[points, gridSize] = Validation.aux.findCheckerboard(wFrame.i);
if (verbose)
    figure; imagesc(wFrame.i); hold on; plot(points(:,1),points(:,2),'+r');
end

if (gridSize(2) ~= gridSizeSph(2))
    xPts = reshape(points(:,1), gridSize);
    yPts = reshape(points(:,2), gridSize);
    nSkip = gridSize(2)-gridSizeSph(2);
    xPts = xPts(:,1:end-nSkip);
    yPts = yPts(:,1:end-nSkip);
    points = zeros(size(ptsSph));
    points(:,1) = reshape(xPts, size(ptsSph,1),1);
    points(:,2) = reshape(yPts, size(ptsSph,1),1);
    gridSize = size(xPts);
end
    
if (verbose)
    figure; imagesc(wFrame.i); hold on; plot(points(:,1),points(:,2),'+r');
end

if (~isequal(gridSizeSph, gridSize))
    error('The grids of spherical and world frames do not match');
end

params = Validation.aux.defaultMetricsParams();
params.camera = wCap.camera;
params.target.squareSize = 20;
[score, ~] = Validation.metrics.gridInterDist(wFrame, params);
if (score > 2.0)
    warning('World frame has bad accuracy: interDist of %.2f', score);
end

v = Validation.aux.pointsToVertices(points, wFrame.z, wCap.camera);

[mAngX,mAngY] = vertices2mirrorAngles(v, wCap.regs);
if (verbose)
    figure; plot(mAngX,mAngY, '.-'); title('mirror angles from the checkeckboard');
end


%%
[dsmAngX, dsmAngY] = sphericalXY2dsmAngle(ptsSph(:,1), ptsSph(:,2), sphRegs);
if (verbose)
    figure; plot(dsmAngX, dsmAngY, '.-'); title('mirror angles from the spherical checkeckboard');
end

%% compare dsm vs real world mirror
if (verbose)
    figure; plot(mAngX,mAngY, '.-'); title('real world mirror angles vs dsm angles');
    hold on; plot(dsmAngX/2, dsmAngY/2, '.-');
end

%%
%[Y,X]=ndgrid(1:360,1:640);
%FwAngX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),wAngX);
%FwAngY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),wAngY);
FmAngX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),mAngX);
FmAngY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),mAngY);

%WAngX = FwAngX(X,Y); figure; imagesc(WAngX); title 'World angle X in spherical image';
%WAngY = FwAngY(X,Y); figure; imagesc(WAngY); title 'World angle Y in spherical image';

%% spherical to XY of IR image
FSph2ImgX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),points(:,1));
FSph2ImgY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),points(:,2));

%% mclog
%iLog = 8;
%mclog = mcLog(iLog);
mclog = sphCap.mclog;
%figure; plot(mclog.angX,mclog.angY, '.-');
[xSph,ySph] = angle2sphericalXY(mclog.angX, mclog.angY, sphRegs);
if (verbose || ~isempty(fileName))
    figure; imagesc(irSph); hold on; plot(xSph,ySph, '.-r');
    title(sprintf('%s: spherical with PZR data', fileName));
end

%% show PZR angles on the real world checker
dsmInX = FSph2ImgX(xSph,ySph);
dsmInY = FSph2ImgY(xSph,ySph);
if (verbose)
    figure; imagesc(wFrame.i); hold on; plot(dsmInX, dsmInY, '.-r');
    title('Real world image with PZR data');
end

%% PZR to real world dsm
actMirAngX = FmAngX(xSph,ySph);
actMirAngY = FmAngY(xSph,ySph);
if (verbose)
    figure; plot(actMirAngX, actMirAngY, '.-');
end

%% compare PZR angles to real world mirror angles
if (verbose)
    figure; plot(actMirAngX, actMirAngY, '.-');
    hold on; plot(mclog.angX/2,mclog.angY/2, '.-');
    
    figure; plot(actMirAngX, '.-'); hold on; plot(mclog.angX/2, '.-');
    figure; plot(actMirAngY, '.-'); hold on; plot(mclog.angY/2, '.-');
end
   
%% output

res = mclog;
res.angX = mclog.angX/2;
res.angY = mclog.angY/2;

res.actAngX = actMirAngX;
res.actAngY = actMirAngY;

end

