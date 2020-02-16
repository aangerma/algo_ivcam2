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


% load('X:\Data\IvCam2\OnlineCalibration\Simulator\simulatedCB.mat');
% camerasParams.rgbPmat(1) = camerasParams.rgbPmat(1)*1.003;
% Take first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);

% frame.z = circshift(frame.z(:,:,1),[0,2]);
% frame.i = circshift(frame.i(:,:,1),[0,2]);

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

% [frame.wIm,frame.W,frame.validMask] = OnlineCalibration.aux.calcDepthWeights(frame.z,frame.i,options);
% 
% 
% figure,imagesc(frame.wIm);
% figure,imagesc(frame.validMask); title('Depth Edge Pixels');
% 
% frame.z(:) = 2000;
% frame.V = OnlineCalibration.aux.z2vertices(single(frame.z),frame.validMask,params);
% 
% [frame.V] = OnlineCalibration.aux.verticesFromSubEdges(frame.z,options);
[frame.V,frame.W,frame.edgePts] = OnlineCalibration.aux.verticesFromSubEdges(frame, params,options);
% frames.V = frames.V(5000,:);
% Map the edges to the RGB image
% frames.uvMap = projectVToRGB(frames.V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
%C = calculateCost(frames.V,frames.W,frames.D,camerasParams);
[gradNormMat] = OnlineCalibration.aux.normalizeGradMat(params,frame);
% calculate cost and gradient
uvMapOrig = OnlineCalibration.aux.projectVToRGB(frame.V,params.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
origParams = params;
uvRMS(1) = OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0);
for k = 1:20
initRgbPmat = camerasParams.rgbPmat;
[C,gradStruct] = OnlineCalibration.aux.costGrad(initRgbPmat,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort);
grad = gradStruct.A;
grad(3,:) = 0;
grad = grad.*gradNormMat;

% grad(3,:) = 0;
normedGrad = grad/norm(grad);

alpha = (0:0.0005:0.02)*50;
cParams = camerasParams;
for i = 1:numel(alpha)
    RgbPmat = initRgbPmat + alpha(i)*normedGrad;
    cParams.rgbPmat = RgbPmat;
    C(i) = OnlineCalibration.aux.calculateCost(frame.V,frame.W,frame.D,cParams);
end
% figure, plot(alpha,C); title('cost along gradient direction')
[cMax,mI] = max(C);
RgbPmat = initRgbPmat + alpha(mI)*normedGrad;

time = toc(startTime);
params.rgbPmat = RgbPmat;
uvRMS(k+1) = OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0);
camerasParams.rgbPmat = RgbPmat;
fprintf('Calculating an iteration took %3.2f seconds. UV RMS = %2.2f. Cost = %f.\n',time,uvRMS(k),cMax);

end
% show original and new
uvMapNext = OnlineCalibration.aux.projectVToRGB(frame.V,RgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);



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
newParams = params;
newParams.rgbPmat = RgbPmat;
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);

figure,
plot(0:numel(uvRMS)-1,uvRMS);
xlabel('iter #');
ylabel('UV RMS Error');
title('UV Error Over Iterations');
grid minor;