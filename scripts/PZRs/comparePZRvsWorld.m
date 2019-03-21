% input
% frame30
% irSpherical
% mclog

%% compute world vertices
[points, gridSize] = Validation.aux.findCheckerboard(frame30.i);
figure; imagesc(frame30.i); hold on; plot(points(:,1),points(:,2),'+r');
camera.zMaxSubMM = 2^regs.GNRL.zMaxSubMMExp;
camera.K = reshape([typecast(regs.FRMW.kRaw,'single')';1],3,3)';

params = Validation.aux.defaultMetricsParams();
params.camera = camera;
params.target.squareSize = 20;
[score, results] = Validation.metrics.gridInterDist(frame30, params);

v = Validation.aux.pointsToVertices(points, frame30.z, camera);

%% compute world and mirror angles
[wAngX,wAngY] = vertices2worldAngles(v, regs);
figure; plot(wAngX,wAngY, '.-'); title('world angles from the checkeckboard');

[mAngX,mAngY] = vertices2mirrorAngles(v, regs);
figure; plot(mAngX,mAngY, '.-'); title('mirror angles from the checkeckboard');


%% find checkerboard corners in ir spherical 
irSpherical = fillHolesMM(irSpherical);

[ptsSph, gridSizeSph] = Validation.aux.findCheckerboard(irSpherical);
figure; imagesc(irSpherical); hold on; plot(ptsSph(:,1),ptsSph(:,2),'+r');

%{
%% compute corners dsm angles
[dsmAngX, dsmAngY] = sphericalXY2dsmAngle(ptsSph(:,1),ptsSph(:,2),regs);
figure; plot(dsmAngX, dsmAngY, '.-'); title('mirror angles from the spherical checkeckboard');

%% compare dsm vs real world mirror
figure; plot(mAngX,mAngY, '.-'); title('real world mirror angles vs dsm angles');
hold on; plot(dsmAngX/2, dsmAngY/2, '.-'); 
%}

%% spherical pixels to mirror angles
[Y,X]=ndgrid(1:360,1:640);
FmAngX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),mAngX);
FmAngY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),mAngY);

%% spherical to XY of IR image
FSph2ImgX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),points(:,1));
FSph2ImgY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),points(:,2));

%% mclog to spherical image
[xSph,ySph] = angle2sphericalXY(mclog.angX,mclog.angY,regs);
figure; imagesc(irSpherical); hold on; plot(xSph,ySph, '.-w');

%% show PZR angles on the real world checker
dsmInX = FSph2ImgX(xSph,ySph);
dsmInY = FSph2ImgY(xSph,ySph);
figure; imagesc(frame30.i); hold on; plot(dsmInX, dsmInY, '.-w');

%% PZR angles to real world mirror angles
dsmMAngX = FmAngX(xSph,ySph);
dsmMAngY = FmAngY(xSph,ySph);
figure; plot(dsmMAngX, dsmMAngY, '.-');

%% compare PZR angles to real world mirror angles

figure; plot(dsmMAngX, dsmMAngY, '.-'); title('dsm angles vs real mirror angles');
hold on; plot(mclog.angX/2,mclog.angY/2, '.-');

% compare angle X
figure; plot(dsmMAngX, '.-'); title('dsm angles X vs real mirror angles X');
hold on; plot(mclog.angX/2, '.-');

% compare angle Y
figure; plot(dsmMAngY, '.-');  title('dsm angles Y vs real mirror angles Y');
hold on; plot(mclog.angY/2, '.-');




