clear
close all

%% Load frames from IPDev
dirname = 'X:\Data\IvCam2\OnlineCalibration';
subdir = fullfile(dirname,'F9440842_scene1','ZIRGB');

% Load data of scene 
frame = OnlineCalibration.aux.loadZIRGBFrames(subdir);

% Load unitData
load(fullfile(dirname,'F9440842_scene1','camerasParams.mat'));


% load('X:\Data\IvCam2\OnlineCalibration\Simulator\simulatedCB.mat');
% camerasParams.rgbPmat(1) = camerasParams.rgbPmat(1)*1.001;
% Take first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);
frame.yuy2 = frame.yuy2(:,:,1);
params = camerasParams;
params.cbGridSz = [9,13];

startTime = tic;

% [ptsEdges,ptsPixeled] = OnlineCalibration.aux.subpixelEdges(frame.z,200);

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

% % Work on Z image after noise filtering
% [frames.Ez] = calcEImage(frames(1).z(:,:,1),options);
% [frames.Ei] = calcEImage(frames(1).i(:,:,1),options);
% figure,imagesc(frames.Ei); title('E IR image');
% figure,imagesc(frames.Ez); title('E Z image');

[frame.wIm,frame.W,frame.validMask] = OnlineCalibration.aux.calcDepthWeights(frame.z,frame.i,options);
frame.W = frame.W./max(frame.W(:));

figure,imagesc(frame.wIm);
figure,imagesc(frame.validMask); title('Depth Edge Pixels');

frame.V = OnlineCalibration.aux.z2vertices(single(frame.z),frame.validMask,params);


% frames.V = frames.V(5000,:);
% Map the edges to the RGB image
% frames.uvMap = projectVToRGB(frames.V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
%C = calculateCost(frames.V,frames.W,frames.D,camerasParams);

% calculate cost and gradient
initRgbPmat = camerasParams.rgbPmat;
initRgb = camerasParams.Rrgb;
[initXAlpha,initYBeta,initZGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(camerasParams.Rrgb);
[C,grad] = OnlineCalibration.aux.costGrad(initRgbPmat,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort,'ART',camerasParams.Rrgb,camerasParams.Trgb);

%%
%Debug:
%{
epsilon = 10e-10*12;

rgbPmatNewPlus = initRgbPmat;
rgbPmatNewPlus(1,3) = rgbPmatNewPlus(1,3) + epsilon;
[CnewPlus,gradNewPlus] = OnlineCalibration.aux.costGrad(rgbPmatNewPlus,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort,'ART',camerasParams.Rrgb,camerasParams.Trgb);
rgbPmatNewMinus = initRgbPmat;
rgbPmatNewMinus(1,3) = rgbPmatNewMinus(1,3) - epsilon;
[CnewMinus,gradNewMinus] = OnlineCalibration.aux.costGrad(rgbPmatNewMinus,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort,'ART',camerasParams.Rrgb,camerasParams.Trgb);


RnewPlus = OnlineCalibration.aux.calcRmatRromAngs(initXAlpha+epsilon,initYBeta,initZGamma);
rgbPmatNewPlus = camerasParams.Krgb*[RnewPlus,camerasParams.Trgb];
[CnewPlus,gradNewPlus] = OnlineCalibration.aux.costGrad(rgbPmatNewPlus,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort,'ART',RnewPlus,camerasParams.Trgb);
RnewMinus = OnlineCalibration.aux.calcRmatRromAngs(initXAlpha-epsilon,initYBeta,initZGamma);
rgbPmatNewMinus = camerasParams.Krgb*[RnewMinus,camerasParams.Trgb];
[CnewMinus,gradNewMinus] = OnlineCalibration.aux.costGrad(rgbPmatNewMinus,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort,'ART',RnewMinus,camerasParams.Trgb);


x = 10e8;
f = x.^2+5;
CnewPlus = (x+epsilon).^2+5;
CnewMinus = (x-epsilon).^2+5;
gradNumerical = (CnewPlus-CnewMinus)/(2*epsilon);
disp(['Epsilon: ' num2str(epsilon)]);
disp(['Numerical Gradient: ' num2str(gradNumerical)]);
% disp(['Calculated Gradient: ' num2str(grad.xAlpha)]);
disp(['Calculated Gradient: ' num2str(grad.xAlpha)]);
disp(['Numerical Gradient/Calculated Gradient: ' num2str(gradNumerical /grad.xAlpha)]);
%}
%%

alpha = 0:0.0005:0.02;
cParams = camerasParams;
for i = 1:numel(alpha)
%     RgbPmat = initRgbPmat + alpha(i)*normedGrad;
    xAlpha = initXAlpha + alpha(i)*grad.xAlpha;
    xBeta = initYBeta + alpha(i)*grad.yBeta;
    zGamma = initZGamma + alpha(i)*grad.zGamma;
    Rrgb = OnlineCalibration.aux.calcRmatRromAngs(xAlpha,xBeta,zGamma);
    cParams.rgbPmat = camerasParams.Krgb*[Rrgb,camerasParams.Trgb];
    C(i) = OnlineCalibration.aux.calculateCost(frame.V,frame.W,frame.D,cParams);
end
figure, plot(alpha,C); title('cost along gradient direction')
[~,mI] = max(C);
% RgbPmat = initRgbPmat + alpha(mI)*normedGrad;
xAlpha = initXAlpha + alpha(mI)*grad.xAlpha;
xBeta = initYBeta + alpha(mI)*grad.yBeta;
zGamma = initZGamma + alpha(mI)*grad.zGamma;
Rrgb = OnlineCalibration.aux.calcRmatRromAngs(xAlpha,xBeta,zGamma);
RgbPmat = camerasParams.Krgb*[Rrgb,camerasParams.Trgb];

time = toc(startTime);
fprintf('Calculating an iteration took %3.2f seconds\n',time);


% show original and new
uvMapOrig = OnlineCalibration.aux.projectVToRGB(frame.V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
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


OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
newParams = params;
newParams.rgbPmat = RgbPmat;
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);


