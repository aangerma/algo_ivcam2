clear
% close all
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
frame.yuy2Prev = frame.yuy2;
% Define hyperparameters

params = camerasParams;
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);

params.cbGridSz = [9,13];% not part of the optimization 
params.inverseDistParams.alpha = 1/3;
params.inverseDistParams.gamma = 0.98;
params.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
params.gradITh = 3.5; % Ignore pixels with IR grad of less than this
params.gradZTh = 25; % Ignore pixels with Z grad of less than this
params.gradZMax = 1000; 
% params.derivVar = 'P';
params.maxStepSize = 1;
params.tau = 0.5;
params.controlParam = 0.5;
params.minStepSize = 1e-5;
params.maxBackTrackIters = 50;
params.minRgbPmatDelta = 1e-5;
params.minCostDelta = 1;
params.maxOptimizationIters = 50;
params.zeroLastLineOfPGrad = 1;
params.constLastLineOfP = 0;
% params.rgbPmatNormalizationMat = [0.3242,     0.4501,    0.2403,   359.3750;      0.3643,     0.5074      0.2689     402.3438;      0.0029     0.0040     0.0021     3.2043];
% params.rgbPmatNormalizationMat = [0.35682896, 0.26685065,1.0236474,0.00068233482; 0.35521242, 0.26610452, 1.0225836, 0.00068178622; 410.60049, 318.23358, 1205.4570, 0.80363423];
params.rgbPmatNormalizationMat = [0.35369244,0.26619774,1.0092601,0.00067320449;0.35508525,0.26627505,1.0114580,0.00067501375;414.20557,313.34106,1187.3459,0.79157025];
params.KrgbMatNormalizationMat = [0.35417202,0.26565930,1.0017655;0.35559174,0.26570305,1.0066491;409.82886,318.79565,1182.6952];
params.RnormalizationParams = [1508.9478;1604.9430;649.38434];
params.TmatNormalizationMat = [0.91300839;0.91698289;0.43305457];

params.edgeThresh4logicIm = 0.1;
params.seSize = 3;
params.moveThreshPixVal = 20;
params.moveThreshPixNum =  3e-05*prod(params.rgbRes);
params.moveGaussSigma = 1;
params.maxXYMovementPerIteration = [10,2,2];
params.maxXYMovementFromOrigin = 20;
params.numSectionsV = 2;
params.numSectionsH = 2;

sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);


params.edgeDistributMinMaxRatio = 0.005;
params.minWeightedEdgePerSectionDepth = 50;
params.minWeightedEdgePerSectionRgb = 0.05;

startParams = params;
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


% Preprocess Z and IR
% [frame.irEdge] = OnlineCalibration.aux.preprocessIR(frame,params);
% [frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges] = OnlineCalibration.aux.preprocessZ(frame,params);
[frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges] = OnlineCalibration.aux.preprocessZAndIR(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',single(frame.zEdge),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSubPixel',single(frame.zEdgeSubPixel),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSupressed',single(frame.zEdgeSupressed),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_valuesForSubEdges',single(frame.zValuesForSubEdges),'single');


[frame.vertices] = OnlineCalibration.aux.subedges2vertices(frame,params);
frame.weights = OnlineCalibration.aux.calculateWeights(frame,params);
frame.sectionMapDepth = sectionMapDepth(frame.zEdgeSupressed>0);
frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(frame.vertices),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weights',single(frame.weights),'single');

%% Validate input scene
if ~OnlineCalibration.aux.validScene(frame,params)
    disp('Scene not valid!');
    return;
end
%% Perform Optimization
params.derivVar = 'KrgbRT';
newParams = OnlineCalibration.Opt.optimizeParameters(frame,params);
params.derivVar = 'P';
newParamsP = OnlineCalibration.Opt.optimizeParametersP(frame,params);

OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParamsP,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);
ax = gca;
title({ax.Title.String;'New R,T,Krgb optimization'});
%% Validate new parameters
[validParams,updatedParams,dbg] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,startParams,1);
if validParams
    params = updatedParams;
end


figure;
imagesc(frame.yuy2);
hold on;
% plot(dbg.uvMap(:,1),dbg.uvMap(:,2),'*r','markersize',1)
% plot(dbg.uvMapNew(:,1),dbg.uvMapNew(:,2),'*g','markersize',1)
quiver(dbg.uvMap(:,1),dbg.uvMap(:,2),dbg.uvMapNew(:,1)-dbg.uvMap(:,1),dbg.uvMapNew(:,2)-dbg.uvMap(:,2),'r')

figure;
imagesc(frame.z);
hold on;
plot(frame.zEdgeSubPixel(:,:,2),frame.zEdgeSubPixel(:,:,1),'*g','markersize',1)

figure;
imagesc(frame.i);
hold on;
plot(frame.zEdgeSubPixel(:,:,2),frame.zEdgeSubPixel(:,:,1),'*g','markersize',1)
% figure; 
% subplot(421); imagesc(frame.i); impixelinfo; title('IR image');colorbar;
% subplot(422); imagesc(frame.irEdge); impixelinfo; title('IR edge');colorbar;
% subplot(423);imagesc(frame.z./4); impixelinfo; title('Depth image');colorbar;
% subplot(424);imagesc(frame.zEdgeSupressed>0); impixelinfo; title('zEdgeSupressed image');colorbar;
% subplot(425);imagesc(frame.yuy2); impixelinfo; title('Color image');colorbar;
% subplot(426);imagesc(frame.rgbEdge); impixelinfo; title('Color edge');colorbar;
% subplot(427);imagesc(frame.rgbIDT); impixelinfo; title('Color IDT');colorbar;
