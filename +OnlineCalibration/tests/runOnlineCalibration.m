clear
close all
%% Load frames from IPDev
sceneDir = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\F9440842_scene2';
imagesSubdir = fullfile(sceneDir,'ZIRGB');
intrinsicsExtrinsicsPath = fullfile(sceneDir,'camerasParams.mat');
outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images

% Load data of scene 
load(intrinsicsExtrinsicsPath);
frame = OnlineCalibration.aux.loadZIRGBFrames(imagesSubdir);
% Keep only the first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);
frame.yuy2 = frame.yuy2(:,:,1);

% Define hyperparameters

params = camerasParams;
params.cbGridSz = [9,13];
params.inverseDistParams.alpha = 1/3;
params.inverseDistParams.gamma = 0.98;
params.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
params.gradITh = 1.5; % Ignore pixels with IR grad of less than this
params.gradZTh = 25; % Ignore pixels with Z grad of less than this
params.derivVar = 'P';
params.maxStepSize = 1;
params.tau = 0.5;
params.controlParam = 0.5;
params.minStepSize = 1e-5;
params.maxBackTrackIters = 50;
params.minRgbPmatDelta = 1e-5;
params.minCostDelta = 1;
params.maxOptimizationIters = 50;
params.rgbPmatNormalizationMat=    [0.3242    0.4501    0.2403  359.3750
                                    0.3643    0.5074    0.2689  402.3438
                                    0.0029    0.0040    0.0021    3.2043];

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
frame.weights = frame.zEdgeSupressed(frame.zEdgeSupressed>0);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(frame.vertices),'single');



%% Perform Optimization
newParams = OnlineCalibration.Opt.optimizeParameters(frame,params);

OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);
