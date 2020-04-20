clear
close all

%% Load frames from IPDev
dirname = 'X:\Data\IvCam2\OnlineCalibration';
subdir = fullfile(dirname,'F9440842_scene2','ZIRGB');

% Load data of scene
frame = OnlineCalibration.aux.loadZIRGBFrames(subdir);

% Load unitData
% load(fullfile(dirname,'F9340892','camerasParams.mat'));
% load(fullfile(dirname,'F9440842','camerasParams.mat'));
load(fullfile(dirname,'F9440842_scene2','camerasParams.mat'));

% Take first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);

frame.yuy2 = frame.yuy2(:,:,1);
params = camerasParams;
params.cbGridSz = [9,13];

options.edgeMethod = 'sobel';
% options.edgeMethod = 'maxDiff';
options.inverseDistParams.alpha = 1/3;
options.inverseDistParams.gamma = 0.98;
options.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
options.gradITh = 10; % Ignore pixels with IR grad of less than this
options.gradZTh = 200; % Ignore pixels with Z grad of less than this

% Compute E image
[frame.E] = OnlineCalibration.aux.calcEImage(frame.yuy2,options);
figure,imagesc(frame.E); title('RGB Edges');


% Compute inverse distance transform
[frame.D] = OnlineCalibration.aux.calcInverseDistanceImage(frame.E,options.inverseDistParams);
frame.D = frame.D./max(frame.D(:));

figure,imagesc(frame.D); title('RGB IDT');
% Compute Dx and Dy - the gradient images of D
[frame.Dx,frame.Dy] = imgradientxy(frame.D);% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]


[frame.V,frame.W,frame.edgePts] = OnlineCalibration.aux.verticesFromSubEdges(frame, params,options);
frame.W = frame.W./max(frame.W(:));

% [gradNormMat] = OnlineCalibration.aux.normalizeGradMat(params,frame);
% calculate cost and gradient
uvMapOrig = OnlineCalibration.aux.projectVToRGB(frame.V,params.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
origParams = params;
params.verbose = true;
[uvRMS,newParams] = OnlineCalibration.aux.gradAscend(frame,params);

% show original and new
uvMapNext = OnlineCalibration.aux.projectVToRGB(frame.V,newParams.rgbPmat,newParams.Krgb,newParams.rgbDistort);



figure;
tabplot;
imagesc(frame.yuy2);
hold on;
plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'r*')
title('orig');
tabplot;
imagesc(frame.yuy2);
hold on;
plot(uvMapNext(:,1)+1,uvMapNext(:,2)+1,'r*')
title('next step');


figure;
subplot(121);
imagesc(frame.D);
hold on;
plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'r*')
title('orig');
subplot(122);
imagesc(frame.D);
hold on;
plot(uvMapNext(:,1)+1,uvMapNext(:,2)+1,'r*')
title('next step');
linkaxes;


OnlineCalibration.Metrics.calcUVMappingErr(frame,origParams,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);

figure,
plot(0:numel(uvRMS)-1,uvRMS);
xlabel('iter #');
ylabel('UV RMS Error');
title('UV Error Over Iterations');
grid minor;