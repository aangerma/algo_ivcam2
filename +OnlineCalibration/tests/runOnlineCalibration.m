clear

global runParams;
runParams.loadSingleScene = 1;
% runParams.verbose = 0;
% runParams.saveBins = 0;
% runParams.ignoreSceneInvalidation = 1;
% runParams.ignoreOutputInvalidation = 1;
LRS = false;
% close all
%% Load frames from IPDev
sceneDir = 'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\1';
if LRS
    sceneDir = '\\ger\ec\proj\ha\RSG\SA_3DCam\Avishag\ForMaya\305';
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
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir,[],LRS);


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
originalParams = params;

sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);

% Save Inputs
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(frame.z),'uint16');
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(frame.i),'uint8');
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(frame.yuy2),'uint8');

% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',double(frame.rgbEdge),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',frame.rgbIDT,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',frame.rgbIDTx,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',frame.rgbIDTy,'double');

% Preprocess Z and IR
[frame.irEdge,frame.zEdge,frame.xim,frame.yim,frame.zValuesForSubEdges,frame.zGradInDirection,frame.dirPerPixel,frame.weights,frame.vertices,frame.sectionMapDepth,frame.relevantPixelsImage] = OnlineCalibration.aux.preprocessDepth(frame,params);
frame.originalVertices = frame.vertices;

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_edge',frame.irEdge,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',frame.zEdge,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_xim',frame.xim,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_yim',frame.yim,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_valuesForSubEdges',single(frame.zValuesForSubEdges),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'zGradInDirection',single(frame.zGradInDirection),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'dirPerPixel',single(frame.dirPerPixel),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weights',double(frame.weights),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',double(frame.vertices),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapDepth',double(frame.sectionMapDepth),'double');


%% decisionParams from input scene
[~,validInputStruct,isMovement] = OnlineCalibration.aux.validScene(frame,params);
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);
%% Perform Optimization
params.derivVar = 'P';
[newParamsP,decisionParams.newCost] = OnlineCalibration.Opt.optimizeParametersP(frame,params);
newParams = newParamsP;
[newParams.Krgb,newParams.Rrgb,newParams.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsP.rgbPmat);
newParams.Krgb(1,2) = 0;
newParams.Kdepth([1,5]) = newParams.Kdepth([1,5])./newParams.Krgb([1,5]).*params.Krgb([1,5]);
newParams.Krgb([1,5]) = originalParams.Krgb([1,5]);
newParams.rgbPmat = newParams.Krgb*[newParams.Rrgb,newParams.Trgb];

%{
% Debug
OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParamsP,1);
OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);
%}

%% Validate new parameters
[~,updatedParams,dbg,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,originalParams,1);


% Merge all decision params
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct); 
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validInputStruct); 

[validFixBySVM,~] = OnlineCalibration.aux.validBySVM(decisionParams,newParamsP);
validParams = ~isMovement && validFixBySVM; 

if validParams
    params = updatedParams;
end
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'costDiffPerSection',dbg.scoreDiffPersection,'double');

%{
% Debug
figure; 
subplot(421); imagesc(frame.i); impixelinfo; title('IR image');colorbar;
subplot(422); imagesc(frame.irEdge); impixelinfo; title('IR edge');colorbar;
subplot(423);imagesc(frame.z./4); impixelinfo; title('Depth image');colorbar;
subplot(424);imagesc(frame.zEdgeSupressed>0); impixelinfo; title('zEdgeSupressed image');colorbar;
subplot(425);imagesc(frame.yuy2); impixelinfo; title('Color image');colorbar;
subplot(426);imagesc(frame.rgbEdge); impixelinfo; title('Color edge');colorbar;
subplot(427);imagesc(frame.rgbIDT); impixelinfo; title('Color IDT');colorbar;
%}