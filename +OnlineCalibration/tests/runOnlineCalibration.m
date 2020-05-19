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

if LRS
  
else
    % Raw AC data from unit,
    % acDataBin and calibDataBin are different between units, in the below
    % example the data describes the tables without headers
    % DSM regs change during streaming, should be read after taking special frame
    % The below data is an example read from a unit
    binWithHeaders = 0;
    acDataBin = [255,255,255,255,255,255,255,255,255,255,1,0,0,0,0,0,0,0,128,63,0,0,128,63,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255,255,255,255,255];
    calibDataBin = [213,2,0,0,186,5,0,0,198,120,143,255,135,16,204,255,0,0,0,32,193,174,85,163,69,174,85,163,69,174,85,163,69,204,28,132,66,204,28,132,66,204,28,132,66,204,28,132,66,204,28,132,66,8,12,98,66,8,12,98,66,8,12,98,66,8,12,98,66,8,12,98,66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,221,36,134,63,86,92,187,190,115,0,33,0,51,0,48,0,0,0,213,254,121,66,25,205,144,66,32,220,7,66,65,96,224,65,116,0,0,128,152,129,1,0,7,0,0,0,0,4,224,1,0,0,0,0,174,0,149,66,0,0,0,0,144,130,133,66,231,1,0,0,231,1,0,0,231,1,0,0,231,1,0,0,231,1,0,0,240,0,0,0,240,0,0,0,240,0,0,0,240,0,0,0,240,0,0,0,69,23,131,66,146,142,3,64,72,239,7,64,254,111,6,64,137,65,24,58,8,172,4,58,237,81,32,58,193,135,102,66,159,74,208,63,85,71,18,64,149,40,215,63,163,4,22,64,138,54,214,63,57,39,21,64,96,12,119,64,44,116,168,193,104,235,74,193,48,106,28,66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,70,91,165,61,83,255,69,59,93,204,5,185,135,151,113,54,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,61,10,143,64,61,10,143,64,204,204,204,61,158,140,191,63,133,205,193,63,254,247,134,7,146,248,230,7,252,248,255,6,17,249,17,7,23,176,132,63,89,85,131,66,0,0,0,0,0,0,0,0,0,0,0,0,94,116,21,66,75,182,93,63,129,134,68,64,234,46,155,191,87,175,103,62,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    dsmRegs.dsmYoffset = 1105140358;
    dsmRegs.dsmXoffset = 1107488894;
    dsmRegs.dsmYscale = 1116837726;
    dsmRegs.dsmXscale = 1115418352;
    
end
% Prepare AC table data for usage
[acData,regs,dsmRegs] = OnlineCalibration.K2DSM.parseCameraDataForK2DSM(dsmRegs,acDataBin,calibDataBin,binWithHeaders);


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
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'relevantPixelsImage',double(frame.relevantPixelsImage),'double');


%% decisionParams from input scene
[~,validInputStruct,isMovement] = OnlineCalibration.aux.validScene(frame,params);
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);


%% Set initial value for some variables that change between iterations
currentFrameCand = frame;
newParamsK2DSM = params;
newParamsK2DSMCand = params;
converged = false;
iterNum = 0;
lastCost = decisionParams.initialCost;
dsmRegsCand = dsmRegs;
acDataCand = acData;


[~,~,newParamsKzFromP] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand);
while ~converged && iterNum < params.maxK2DSMIters
    % K2DSM
    [currentFrameCand,newParamsK2DSMCand,acDataCand,dsmRegsCand] = OnlineCalibration.K2DSM.convertNewK2DSM(frame,newParamsKzFromP,acData,dsmRegs,regs,params);
    % Optimize P
    [newCostCand,newParamsPCand,newParamsKzFromPCand] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand);
    if newCostCand < lastCost
        % End iterations
        converged = 1;
    else
        iterNum = iterNum + 1;
        frame = currentFrameCand;
        lastCost = newCostCand;
        newCost = newCostCand;
        newParamsP = newParamsPCand;
        newParamsKzFromP = newParamsKzFromPCand;
        newParamsK2DSM = newParamsK2DSMCand;
        acData = acDataCand;
        dsmRegs = dsmRegsCand;
    end    
end

%% Validate new parameters
[finalParams,dbg,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(frame,params,newParamsP,newParamsK2DSM,originalParams,params.iterFromStart);
% Merge all decision params
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct); 
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validInputStruct); 
decisionParams.newCost = newCost(end);


[validFixBySVM,~] = OnlineCalibration.aux.validBySVM(decisionParams,params);
validParams = ~isMovement && validFixBySVM; 

if validParams
    params = finalParams;
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