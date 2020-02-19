clear
close all
%% Load frames from IPDev
sceneDir = 'X:\IVCAM2_calibration _testing\19.2.20\Snapshots\LongRange 768X1024 (RGB 1920X1080)\1';
intrinsicsExtrinsicsPath = fullfile(sceneDir,'RecordingStatus.rsc');
outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images

% Load data of scene 
[ipdevParams] = OnlineCalibration.aux.loadIPDevStatusFile(intrinsicsExtrinsicsPath);

% Define hyperparameters
% params = camerasParams;
params.cbGridSz = [9,13];
params.inverseDistParams.alpha = 1/3;
params.inverseDistParams.gamma = 0.98;
params.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
params.gradITh = 1.5; % Ignore pixels with IR grad of less than this
params.gradZTh = 25; % Ignore pixels with Z grad of less than this
params.Trgb = ipdevParams.RGB_translation;
params.Kdepth = ipdevParams.K_depth;
params.depthRes = [ipdevParams.Depth_Vertical_resolution,ipdevParams.Depth_Horizontal_resolution];
params.zMaxSubMM = ipdevParams.Z_scale;
params.Krgb = ipdevParams.K_RGB;
params.rgbDistort = ipdevParams.RGB_distortion';
params.Rrgb = ipdevParams.RGB_rotation;
params.rgbRes = [ipdevParams.RGB_Vertical_resolution,ipdevParams.RGB_Horizontal_resolution];
params.rgbPmat = params.Krgb*[params.Rrgb,params.Trgb];


frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir,params.depthRes,params.rgbRes);
% Keep only the first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);
frame.yuy2 = frame.yuy2(:,:,1);

% Save Inputs
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(frame.z),'uint16');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(frame.i),'uint8');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(frame.yuy2),'uint8');

% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',single(frame.rgbEdge),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',single(frame.rgbIDT),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',single(frame.rgbIDTx),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',single(frame.rgbIDTy),'single');

% Preprocess IR
[frame.irEdge] = OnlineCalibration.aux.preprocessIR(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_edge',single(frame.irEdge),'single');

% Preprocess Z
[frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges] = OnlineCalibration.aux.preprocessZ(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',single(frame.zEdge),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSubPixel',single(frame.zEdgeSubPixel),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSupressed',single(frame.zEdgeSupressed),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_valuesForSubEdges',single(frame.zValuesForSubEdges),'single');


[frame.vertices] = OnlineCalibration.aux.subedges2vertices(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(frame.vertices),'single');


[gradNormMat] = OnlineCalibration.aux.normalizeGradMat(params,frame);

frame.V = frame.vertices;
frame.D = frame.rgbIDT;
frame.Dx = frame.rgbIDTx;
frame.Dy = frame.rgbIDTy;
frame.W = frame.zEdgeSupressed(frame.zEdgeSupressed>0);
camerasParams = params;
% calculate cost and gradient
uvMapOrig = OnlineCalibration.aux.projectVToRGB(frame.V,params.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
origParams = params;
uvRMS(1) = OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0);
for k = 1:100
initRgbPmat = camerasParams.rgbPmat;
[C,grad] = OnlineCalibration.aux.costGrad(initRgbPmat,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,camerasParams.Krgb,camerasParams.rgbDistort);
grad.A(3,:) = 0;
grad.A = grad.A.*gradNormMat;

% grad(3,:) = 0;
normedGrad = grad.A/norm(grad.A);

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

% time = toc(startTime);
params.rgbPmat = RgbPmat;
uvRMS(k+1) = OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0);
camerasParams.rgbPmat = RgbPmat;
% fprintf('Calculating an iteration took %3.2f seconds. UV RMS = %2.2f. Cost = %f.\n',time,uvRMS(k),cMax);

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
