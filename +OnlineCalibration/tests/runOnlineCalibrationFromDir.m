function [] = runOnlineCalibrationFromDir(sceneDir)

% imagesSubdir = fullfile(sceneDir,'ZIRGB');
% intrinsicsExtrinsicsPath = fullfile(sceneDir,'camerasParams.mat');

outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images

% Load data of scene 
% load(intrinsicsExtrinsicsPath);
[camerasParams] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir);
% frame = OnlineCalibration.aux.loadZIRGBFrames(imagesSubdir);
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir);


% Keep only the Second frame
frame.z = frame.z(:,:,2);
frame.i = frame.i(:,:,2);
if size(frame.yuy2,3)<2
    disp(['Not enough RGB frames in: ' num2str(sceneDir)]);
    return;
end
frame.yuy2 = frame.yuy2(:,:,2);
frame.yuy2Prev = frame.yuy2(:,:,1);



% Define hyperparameters
params = camerasParams;
params.cbGridSz = [9,13];% not part of the optimization 
params.inverseDistParams.alpha = 1/3;
params.inverseDistParams.gamma = 0.98;
params.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
params.gradITh = 3.5; % Ignore pixels with IR grad of less than this
params.gradZTh = 25; % Ignore pixels with Z grad of less than this
params.gradZMax = 1000; 
params.derivVar = 'P';
params.maxStepSize = 1;%1;
params.tau = 0.5;
params.controlParam = 0.5;
params.minStepSize = 1e-5;
params.maxBackTrackIters = 50;
params.minRgbPmatDelta = 1e-5;
params.minCostDelta = 1;
params.maxOptimizationIters = 50;
params.zeroLastLineOfPGrad = 1;
% params.rgbPmatNormalizationMat = [0.3242,     0.4501,    0.2403,   359.3750;      0.3643,     0.5074      0.2689     402.3438;      0.0029     0.0040     0.0021     3.2043];
params.rgbPmatNormalizationMat = [0.35682896, 0.26685065,1.0236474,0.00068233482; 0.35521242, 0.26610452, 1.0225836, 0.00068178622; 410.60049, 318.23358, 1205.4570, 0.80363423];
params.edgeThresh4logicIm = 0.1;
params.seSize = 3;
params.moveThreshPixVal = 20;
params.moveThreshPixNum =  3e-05*prod(params.rgbRes);
params.moveGaussSigma = 1;
params.maxXYMovementPerIteration = [10,2,2];
params.maxXYMovementFromOrigin = 20;
params.numSectionsV = 2;
params.numSectionsH = 2;
params.edgeDistributMinMaxRatio = 0.005;
params.minWeightedEdgePerSectionDepth = 3000;
params.minWeightedEdgePerSectionRgb = 30000;

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
[frame.weights] = OnlineCalibration.aux.calculateWeights(frame,params);
sectionMap = OnlineCalibration.aux.sectionPerPixel(params);
frame.sectionMapDepth = sectionMap(frame.zEdgeSupressed>0);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(frame.vertices),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weights',single(frame.weights),'single');


if ~OnlineCalibration.aux.validScene(frame,params)
    disp('Scene not valid!');
    return;
end
%% Perform Optimization
newParams = OnlineCalibration.Opt.optimizeParameters(frame,params);

% 
OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);
h = gca;
origTitle = h.Title.get.String;
title({sceneDir;origTitle});
% figure; 
% subplot(421); imagesc(frame.i); impixelinfo; title('IR image');colorbar;
% subplot(422); imagesc(frame.irEdge); impixelinfo; title('IR edge');colorbar;
% subplot(423);imagesc(frame.z./4); impixelinfo; title('Depth image');colorbar;
% subplot(424);imagesc(frame.zEdgeSupressed>0); impixelinfo; title('zEdgeSupressed image');colorbar;
% subplot(425);imagesc(frame.yuy2); impixelinfo; title('Color image');colorbar;
% subplot(426);imagesc(frame.rgbEdge); impixelinfo; title('Color edge');colorbar;
% subplot(427);imagesc(frame.rgbIDT); impixelinfo; title('Color IDT');colorbar;

end

