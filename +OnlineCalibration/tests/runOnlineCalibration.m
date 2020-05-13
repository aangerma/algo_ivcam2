clear

% global runParams;
% runParams.loadSingleScene = 1;
% runParams.verbose = 0;
% runParams.saveBins = 0;
% runParams.ignoreSceneInvalidation = 1;
% runParams.ignoreOutputInvalidation = 1;
LRS = false;
% close all
%% Load frames from IPDev
sceneDir = 'C:\work\librealsense\build\unit-tests\algo\depth-to-rgb-calibration\19.2.20\F9440687\Snapshots\LongRange_D_768x1024_RGB_1920x1080\2';
if LRS
    sceneDir = 'C:\work\autocal\data\251';
% sceneDir = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\F9440842_scene2';
sceneDir = 'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\2';%13'; %5,7,8,10 no checker %13,15 not as good by =>0.5 pix

% imagesSubdir = fullfile(sceneDir,'ZIRGB');
% intrinsicsExtrinsicsPath = fullfile(sceneDir,'camerasParams.mat');

outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images

% Load data of scene 
% load(intrinsicsExtrinsicsPath);
[camerasParams] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir);
% frame = OnlineCalibration.aux.loadZIRGBFrames(imagesSubdir);
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir);


% Keep only the first frame
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);
frame.yuy2 = frame.yuy2(:,:,1);
frame.yuy2Prev = frame.yuy2;

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
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(frame.z),'uint16');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(frame.i),'uint8');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(frame.yuy2),'uint8');

% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',single(frame.rgbEdge),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',single(frame.rgbIDT),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',single(frame.rgbIDTx),'single');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',single(frame.rgbIDTy),'single');

if  0
%     Old preprocessing
    % Preprocess IR
    [frame.irEdge] = OnlineCalibration.aux.preprocessIR(frame,params);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_edge',single(frame.irEdge),'single');
    
    % Preprocess Z
    [frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges,frame.dirI] = OnlineCalibration.aux.preprocessZ(frame,params);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',single(frame.zEdge),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSubPixel',single(frame.zEdgeSubPixel),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSupressed',single(frame.zEdgeSupressed),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_valuesForSubEdges',single(frame.zValuesForSubEdges),'single');
    [frame.vertices] = OnlineCalibration.aux.subedges2vertices(frame,params);
    frame.weights = OnlineCalibration.aux.calculateWeights(frame,params);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(frame.vertices),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weights',single(frame.weights),'single');
    frame.sectionMapDepth = sectionMapDepth(frame.zEdgeSupressed>0);
else
    [frame.irEdge,frame.zEdge,...
    frame.xim,frame.yim,frame.zValuesForSubEdges...
    ,frame.zGradInDirection,frame.dirPerPixel,frame.weights,frame.vertices,...
    frame.sectionMapDepth,frame.relevantPixelsImage] = OnlineCalibration.aux.preprocessDepth(frame,params);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_edge',single(frame.irEdge),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',single(frame.zEdge),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'xim',single(frame.xim),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'yim',single(frame.yim),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'z_valuesForSubEdges',single(frame.zValuesForSubEdges),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'z_gradInDirection',single(frame.zGradInDirection),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'dirPerPixel',single(frame.dirPerPixel),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weights',single(frame.weights),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(frame.vertices),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapDepth',single(frame.sectionMapDepth),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'relevantPixelsImage',single(frame.relevantPixelsImage),'single');
end

frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);

%% Validate input scene
if ~OnlineCalibration.aux.validScene(frame,params)
    disp('Scene not valid!');
     return;
end
%% Perform Optimization
params.derivVar = 'KrgbRT';
newParams = OnlineCalibration.Opt.optimizeParameters(frame,params);
% params.derivVar = 'P';
% newParamsP = OnlineCalibration.Opt.optimizeParametersP(frame,params);

runOnlineCalibrationOn( sceneDir, LRS );

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
% figure; 
% subplot(421); imagesc(frame.i); impixelinfo; title('IR image');colorbar;
% subplot(422); imagesc(frame.irEdge); impixelinfo; title('IR edge');colorbar;
% subplot(423);imagesc(frame.z./4); impixelinfo; title('Depth image');colorbar;
% subplot(424);imagesc(frame.zEdgeSupressed>0); impixelinfo; title('zEdgeSupressed image');colorbar;
% subplot(425);imagesc(frame.yuy2); impixelinfo; title('Color image');colorbar;
% subplot(426);imagesc(frame.rgbEdge); impixelinfo; title('Color edge');colorbar;
% subplot(427);imagesc(frame.rgbIDT); impixelinfo; title('Color IDT');colorbar;
