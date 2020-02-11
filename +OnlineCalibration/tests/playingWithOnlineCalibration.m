clear
%% Load frames from IPDev
dirname = 'X:\Data\IvCam2\OnlineCalibration';
subdir = fullfile(dirname,'F9340892','ZIRGB');

% Load data of scene 
frame = OnlineCalibration.aux.loadZIRGBFrames(subdir);

% Load unitData
load(fullfile(dirname,'F9340892','camerasParams.mat'));

% Take first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);
frame.yuy2 = frame.yuy2(:,:,1);
params = camerasParams;
params.cbGridSz = [9,13];

startTime = tic;

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
figure,imagesc(frame.D); title('RGB IDT');
% Compute Dx and Dy - the gradient images of D
[frame.Dx,frame.Dy] = imgradientxy(frame.D);% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]

% % Work on Z image after noise filtering
% [frames.Ez] = calcEImage(frames(1).z(:,:,1),options);
% [frames.Ei] = calcEImage(frames(1).i(:,:,1),options);
% figure,imagesc(frames.Ei); title('E IR image');
% figure,imagesc(frames.Ez); title('E Z image');

[frame.wIm,frame.W,frame.validMask] = OnlineCalibration.aux.calcDepthWeights(frame.z,frame.i,options);


figure,imagesc(frame.wIm);
figure,imagesc(frame.validMask); title('Depth Edge Pixels');

frame.V = OnlineCalibration.aux.z2vertices(single(frame.z),frame.validMask,params);


% frames.V = frames.V(5000,:);
% Map the edges to the RGB image
% frames.uvMap = projectVToRGB(frames.V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
%C = calculateCost(frames.V,frames.W,frames.D,camerasParams);

% calculate cost and gradient
initRgbPmat = camerasParams.rgbPmat;
[C,grad] = OnlineCalibration.aux.costGrad(initRgbPmat,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort);
normedGrad = grad/norm(grad);

alpha = 0:0.0005:0.02;
cParams = camerasParams;
for i = 1:numel(alpha)
    RgbPmat = initRgbPmat + alpha(i)*normedGrad;
    cParams.rgbPmat = RgbPmat;
    C(i) = OnlineCalibration.aux.calculateCost(frame.V,frame.W,frame.D,cParams);
end
figure, plot(alpha,C); title('cost along gradient direction')
[~,mI] = max(C);
RgbPmat = initRgbPmat + alpha(mI)*normedGrad;

time = toc(startTime);
fprintf('Calculating an iteration took %3.2f seconds\n',time);


% show original and new
uvMapOrig = OnlineCalibration.aux.projectVToRGB(frame.V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
uvMapNext = OnlineCalibration.aux.projectVToRGB(frame.V,RgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);



figure;
tabplot;
imagesc(frame.yuy2);
hold on;
plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'*')
title('orig');
tabplot;
imagesc(frame.yuy2);
hold on;
plot(uvMapNext(:,1)+1,uvMapNext(:,2)+1,'*')
title('next step');


figure;
tabplot;
imagesc(frame.D);
hold on;
plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'*')
title('orig');
tabplot;
imagesc(frame.D);
hold on;
plot(uvMapNext(:,1)+1,uvMapNext(:,2)+1,'*')
title('next step');


OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
newParams = params;
newParams.rgbPmat = RgbPmat;
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);


