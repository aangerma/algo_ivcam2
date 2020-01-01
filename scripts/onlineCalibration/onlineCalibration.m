% Example on unit F9340203
dirname = 'C:\temp\onlineRGB';
subdir = fullfile(dirname,'optimizedModeWithIR');
load(fullfile(dirname,'camerasParams.mat'));

% Load data of scene 
frames = loadFrames(subdir);

startTime = tic;

options.edgeMethod = 'sobel';
% options.edgeMethod = 'maxDiff';
options.inverseDistParams.alpha = 1/3;
options.inverseDistParams.gamma = 0.98;
options.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
options.gradITh = 10; % Ignore pixels with IR grad of less than this
options.gradZTh = 200; % Ignore pixels with Z grad of less than this

% Compute E image
[frames.E] = calcEImage(frames(1).yuy2(:,:,1),options);
figure,imagesc(frames.E); title('edges');

% Compute inverse distance transform 
[frames.D] = calcInverseDistanceImage(frames.E,options.inverseDistParams);
figure,imagesc(frames.D)
% Compute Dx and Dy - the gradient images of D
[frames.Dx,frames.Dy] = imgradientxy(frames.D);% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]

% % Work on Z image after noise filtering
% [frames.Ez] = calcEImage(frames(1).z(:,:,1),options);
% [frames.Ei] = calcEImage(frames(1).i(:,:,1),options);
% figure,imagesc(frames.Ei); title('E IR image');
% figure,imagesc(frames.Ez); title('E Z image');

[frames.wIm,frames.W,frames.validMask] = calcDepthWeights(frames(1).z(:,:,1),frames(1).i(:,:,1),options);


figure,imagesc(frames.wIm);
figure,imagesc(frames.validMask);

frames.V = z2vertices(single(frames.z(:,:,1)),frames.validMask,camerasParams);


% frames.V = frames.V(5000,:);
% Map the edges to the RGB image
% frames.uvMap = projectVToRGB(frames.V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
%C = calculateCost(frames.V,frames.W,frames.D,camerasParams);

% calculate cost and gradient
initRgbPmat = camerasParams.rgbPmat;
[C,grad] = costGrad(initRgbPmat,frames.D,frames.Dx,frames.Dy,frames.W,frames.V,camerasParams.Krgb,camerasParams.rgbDistort);
normedGrad = grad/norm(grad);

alpha = 0:0.0005:0.02;
cParams = camerasParams;
for i = 1:numel(alpha)
    RgbPmat = initRgbPmat + alpha(i)*normedGrad;
    cParams.rgbPmat = RgbPmat;
    C(i) = calculateCost(frames.V,frames.W,frames.D,cParams);
end
figure, plot(alpha,C); title('cost along gradient direction')
[~,mI] = max(C);
RgbPmat = initRgbPmat + alpha(mI)*normedGrad;

time = toc(startTime);
fprintf('Calculating an iteration took %3.2f seconds\n',time);


% show original and new
uvMapOrig = projectVToRGB(frames.V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
uvMapNext = projectVToRGB(frames.V,RgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);



figure;
tabplot;
imagesc(frames.yuy2(:,:,1));
hold on;
plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'*')
title('orig');
tabplot;
imagesc(frames.yuy2(:,:,1));
hold on;
plot(uvMapNext(:,1)+1,uvMapNext(:,2)+1,'*')
title('next step');


figure;
tabplot;
imagesc(frames.D);
hold on;
plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'*')
title('orig');
tabplot;
imagesc(frames.D);
hold on;
plot(uvMapNext(:,1)+1,uvMapNext(:,2)+1,'*')
title('next step');


