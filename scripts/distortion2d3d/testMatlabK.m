clear variables
clc

res = [480,640];
hw = HWinterface();
hw.startStream(0,[480,640]);
im(1) = hw.getFrame(30);
%%
im(2) = hw.getFrame(30);
%%
im(3) = hw.getFrame(30);
hw.stopStream();

%%

for iIm=1:3
    [ptsCropped(:,:,:,iIm)] = Calibration.aux.CBTools.findCheckerboardFullMatrix(im(iIm).i, 1, [], [], false);
end
meanOver4 = mean(0*ptsCropped+1,4);
ptsCroppedJoint = bsxfun(@times, ptsCropped, meanOver4);
validRows = any(~isnan(ptsCroppedJoint(:,:,1,1)),2);
validCols = any(~isnan(ptsCroppedJoint(:,:,1,1)),1);
ptsCroppedJoint = ptsCroppedJoint(validRows, validCols, :, :);
sz = size(ptsCroppedJoint);

imagePoints = zeros(prod(sz(1:2)),2,3);
for iIm=1:3
    for idim=1:2
        imagePoints(:,idim,iIm) = reshape(ptsCroppedJoint(:,:,idim,iIm),[],1);
    end
end
worldPoints = generateCheckerboardPoints(sz(1:2)+1,30);

cameraParams = estimateCameraParameters(imagePoints,worldPoints, 'ImageSize',res);

for iIm=1:3
    figure(iIm)
    subplot(211)
    imagesc(im(iIm).i)
    hold on
    plot(imagePoints(:,1,iIm), imagePoints(:,2,iIm), 'r+')
    imUndist(iIm).i = undistortImage(im(iIm).i, cameraParams);
    subplot(212)
    imagesc(imUndist(iIm).i)
    colormap gray
end

%%

% camMatrix = cameraMatrix(cameraParams,cameraParams.RotationMatrices(:,:,1),cameraParams.TranslationVectors(:,1));
mtlb.K = cameraParams.IntrinsicMatrix';
% horzUV = K*[tand(35);0;1];
% horzUV = horzUV/horzUV(3);
% vertUV = K*[0;tand(30);1];
% vertUV = vertUV/vertUV(3);
cam.K = hw.getIntrinsics;

%%

uvFrame = [[0,0,0,0.5,0.5,0.5,1,1,1]*res(2); [0,0.5,1,0,0.5,1,0,0.5,1]*res(1); ones(1,9)];
dist = 478; % [mm]
mtlb.world = inv(mtlb.K)*uvFrame*dist;
cam.world = inv(cam.K)*uvFrame*dist;

getProjSize = @(x) max(x,[],2) - min(x,[],2);
mtlb.size = getProjSize(mtlb.world);
cam.size = getProjSize(cam.world);

mtlb.leg = sprintf('Matlab (%.2f X %.2f, AR = %.2f)',mtlb.size(1),mtlb.size(2),mtlb.size(1)./mtlb.size(2));
cam.leg = sprintf('IVCAM2 (%.2f X %.2f, AR = %.2f)',cam.size(1),cam.size(2),cam.size(1)./cam.size(2));

%%

ptsOrder = [1,2,3,6,5,4,7,8,9,3,2,8,7,1];

figure
hold on
plot(mtlb.world(1,ptsOrder), mtlb.world(2,ptsOrder), 'b-')
plot(cam.world(1,ptsOrder), cam.world(2,ptsOrder), 'r-')
grid on
xlabel('x [mm]')
ylabel('y [mm]')
legend(mtlb.leg, cam.leg)
title(sprintf('World Representation (invK * UV plane) at Z=%d[mm]', dist))

% at 478mm 690x480 is observed