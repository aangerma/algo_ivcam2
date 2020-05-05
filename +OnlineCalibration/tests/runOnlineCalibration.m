clear

% global runParams;
% runParams.loadSingleScene = 1;
% runParams.verbose = 0;
% runParams.saveBins = 0;
% runParams.ignoreSceneInvalidation = 1;
% runParams.ignoreOutputInvalidation = 1;
LRS = true;
% close all
%% Load frames from IPDev
sceneDir = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\F9440842_scene2';
if LRS
    sceneDir = 'C:\work\autocal\data\251';
end
% imagesSubdir = fullfile(sceneDir,'ZIRGB');
% intrinsicsExtrinsicsPath = fullfile(sceneDir,'camerasParams.mat');
outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images
% Load data of scene 
% load(intrinsicsExtrinsicsPath);

if LRS
    [camerasParams] = getCameraParamsRaw(sceneDir);
else
    [camerasParams] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir);
end   
% frame = OnlineCalibration.aux.loadZIRGBFrames(imagesSubdir);
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir, LRS);


% Keep only the first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);
frame.yuy2Prev = frame.yuy2(:,:,2);
frame.yuy2 = frame.yuy2(:,:,1);


% Define hyperparameters

params = camerasParams;
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);

params.cbGridSz = [9,13];% not part of the optimization 
[params] = OnlineCalibration.aux.getParamsForAC(params);
%%
startParams = params;

sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);

% Save Inputs
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(frame.z),'uint16');
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(frame.i),'uint8');
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(frame.yuy2),'uint8');

% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',double(frame.rgbEdge),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',frame.rgbIDT,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',frame.rgbIDTx,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',frame.rgbIDTy,'double');

% Preprocess IR
[frame.irEdge] = OnlineCalibration.aux.preprocessIR(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_edge',frame.irEdge,'double');

% Preprocess Z
[frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges,frame.dirI] = OnlineCalibration.aux.preprocessZ(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',frame.zEdge,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_dir',frame.dirI-1,'uint8');  % -1 to match C++ 0-based
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSubPixel',frame.zEdgeSubPixel,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSupressed',frame.zEdgeSupressed,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_valuesForSubEdges',single(frame.zValuesForSubEdges),'double');


[frame.vertices] = OnlineCalibration.aux.subedges2vertices(frame,params);
[frame.weights,weightsT] = OnlineCalibration.aux.calculateWeights(frame,params);
frame.sectionMapDepth = sectionMapDepth(frame.zEdgeSupressed>0);
frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',double(frame.vertices),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weightsT',weightsT,'double');

%% Validate input scene
if ~OnlineCalibration.aux.validScene(frame,params, sceneDir)
    disp('Scene not valid!');
     %return;
end

% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'depthEdgeWeightDistributionPerSectionDepth',validSceneStruct.edgeWeightDistributionPerSectionDepth,'double');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapDepth_trans',uint8(transpose(frames.sectionMapDepth)),'uint8');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightDistributionPerSectionRgb',validSceneStruct.edgeWeightDistributionPerSectionRgb,'double');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapRgb_trans',uint8(transpose(frames.sectionMapRgb)),'uint8');

%% Perform Optimization
params.derivVar = 'KrgbRT';
[newParams, newCost] = OnlineCalibration.Opt.optimizeParameters(frame,params,outputBinFilesPath);
% params.derivVar = 'P';
% newParamsP = OnlineCalibration.Opt.optimizeParametersP(frame,params);

new_calib = calibAndCostToRaw(newParams, newCost);  

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'new_calib',new_calib,'double');


OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
% OnlineCalibration.Metrics.calcUVMappingErr(frame,newParamsP,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);
ax = gca;
title({ax.Title.String;'New R,T,Krgb optimization'});
%% Validate new parameters
[validParams,updatedParams,dbg] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,startParams,1);
if validParams
    params = updatedParams;
end
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'costDiffPerSection',dbg.scoreDiffPersection,'double');

% figure; 
% subplot(421); imagesc(frame.i); impixelinfo; title('IR image');colorbar;
% subplot(422); imagesc(frame.irEdge); impixelinfo; title('IR edge');colorbar;
% subplot(423);imagesc(frame.z./4); impixelinfo; title('Depth image');colorbar;
% subplot(424);imagesc(frame.zEdgeSupressed>0); impixelinfo; title('zEdgeSupressed image');colorbar;
% subplot(425);imagesc(frame.yuy2); impixelinfo; title('Color image');colorbar;
% subplot(426);imagesc(frame.rgbEdge); impixelinfo; title('Color edge');colorbar;
% subplot(427);imagesc(frame.rgbIDT); impixelinfo; title('Color IDT');colorbar;
