% This script shows the way to deteriorate the camera params for AC2

KrgbMatNormalizationMat = [0.35417202,0.26565930,1.0017655;0.35559174,0.26570305,1.0066491;409.82886,318.79565,1182.6952];
RnormalizationParams = [1508.9478;1604.9430;649.38434];
TmatNormalizationMat = [0.91300839;0.91698289;0.43305457];
KdepthMatNormalizationMat = [0.050563768;0.053219523;1.9998592;2.0044701];



%% Update Rotation Matrix (3x3) - part of the extrinsics
movementInRGBImageCausedByEachAngle = [2.1; 1.2; -3]; % The magnitude of movement in the RGB image in pixels, can also be negative, just a random vector
[xAlpha,yBeta,zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(rotationMat);
% To rotate along x axis:
xAlpha = xAlpha + movementInRGBImageCausedByEachAngle(1)./RnormalizationParams(1);
% To rotate along y axis:
yBeta = yBeta + movementInRGBImageCausedByEachAngle(2)./RnormalizationParams(2);
% To rotate along z axis:
zGamma = zGamma + movementInRGBImageCausedByEachAngle(3)./RnormalizationParams(3);
rotationMatNew = OnlineCalibration.aux.calcRmatRromAngs(xAlpha,yBeta,zGamma);


%% Update Translation Vec (3x1) - part of the extrinsics
movementInRGBImageByT = [1; -1; -0.5]; % The magnitude of movement in the RGB image in pixels, can also be negative, just a random vector
T = T + movementInRGBImageByT./TmatNormalizationMat;


%% Update Krgb  - RGB intrinsics
movementInRGBImageByKrgb = [1; -1]; % The magnitude of movement in the RGB image in pixels, can also be negative, just a random vector
Krgb([7;8]) = Krgb([7;8]) + movementInRGBImageByKrgb./KrgbMatNormalizationMat([7;8]);

%% Update DSM scale in the camera  (2 values) - changes camera configuration
scaleInPercentageXY = single2hex([1.02,0.99]);
fwCmdForXScale = sprintf('AC_SET_PARAM 1 %s',scaleInPercentageXY{1});
fwCmdForYScale = sprintf('AC_SET_PARAM 2 %s',scaleInPercentageXY{2});
hw.cmd(fwCmdForXScale);
hw.cmd(fwCmdForYScale);

