function runOnlineCalibration(sceneDir,runType)

disp(sceneDir);
global runParams;
runParams.loadSingleScene = 1;
% runParams.verbose = 0;
% runParams.saveBins = 0;
% runParams.ignoreSceneInvalidation = 1;
% runParams.ignoreOutputInvalidation = 1;

% close all
%% Load frames from IPDev
if isempty(sceneDir)
    switch runType
        case 'iqData'
            sceneDir = '\\rslabs-nas.iil.intel.com\VIDB\AC2 Field Test\Tests\Old\19_05_2020\Danielle\Scene 1\iteration15\ac_15\1';
        case 'lrs'
            sceneDir = '\\ger\ec\proj\ha\RSG\SA_3DCam\Avishag\ForMaya\1698';
        otherwise
            sceneDir = 'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\1';
    end
end
% imagesSubdir = fullfile(sceneDir,'ZIRGB');
% intrinsicsExtrinsicsPath = fullfile(sceneDir,'camerasParams.mat');
outputBinFilesPath = fullfile(pwd,'binFiles'); % Path for saving binary images
% Load data of scene
% load(intrinsicsExtrinsicsPath);
switch runType
    case 'iqData'
        [frame,camerasParams,acInputData] = OnlineCalibration.aux.iqFolderToAlgoInputs(sceneDir);
        binWithHeaders = acInputData.binWithHeaders;
        calibDataBin = [acInputData.calibDataBin{:}];
        acDataBin = [acInputData.acDataBin{:}];
        dsmRegs = acInputData.DSMRegs;
    case 'lrs'
        [frame,camerasParams,acInputData] = getCameraParamsRaw(sceneDir);
        dsmRegs = acInputData.dsmRegs;
        calibDataBin = acInputData.calibDataBin;
        binWithHeaders = acInputData.binWithHeaders;
        acDataBin = acInputData.acDataBin;
    otherwise
        [camerasParams] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir);
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
        
        %%
        % LRS
        %saveDSMParamsRaw(outputBinFilesPath, binWithHeaders, acDataBin, calibDataBin, dsmRegs);
        %%
        frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir);
        % If there's no previous frame, use the first frame (i.e., no movement)
        n_yuys = size( frame.yuy_files, 1 );
        if n_yuys < 2
            frame.yuy2Prev = frame.yuy2;
            frame.yuy_files(2) = frame.yuy_files(1);
        else
            frame.yuy2Prev = frame.yuy2(:,:,2);
            
            % Keep only the first frame
            frame.z = frame.z(:,:,1);
            frame.i = frame.i(:,:,1);
            frame.yuy2 = frame.yuy2(:,:,1);
            %frame.yuy2Prev = frame.yuy2;
        end
end
% Define hyperparameters

params = camerasParams;
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);

% This image is the last RGB image that converged since the last play.
% It is initialized to zeros at the start of stream for easy use in
% the first cycle (Release AC2.1)
frame.lastValidYuy2 = 0*frame.yuy2;
% Auto Trigger Mode
manualTrigger = 0;

% Prepare AC table data for usage
%%
% LRS
% Write the filenames out, so we can easily reproduce in C++
mkdirSafe(outputBinFilesPath);
if strcmp(runType,'lrs')
    fid = fopen( fullfile( outputBinFilesPath, 'yuy_prev_z_i.files' ), 'wt' );
    fprintf( fid, '%s\n%s\n%s\n%s', frame.yuy_files(1).name, frame.yuy_files(2).name, frame.z_files(1).name, frame.i_files(1).name );
    fclose( fid );
end

%%
[acData,regs,dsmRegs] = OnlineCalibration.K2DSM.parseCameraDataForK2DSM(dsmRegs,acDataBin,calibDataBin,binWithHeaders);

%%
% LRS
saveDSMParamsRaw(outputBinFilesPath, binWithHeaders, acDataBin, regs, dsmRegs);
saveCameraParamsRaw(outputBinFilesPath, camerasParams);
% Fill a metadata struct and write it out at the end:
md = struct;
%%

% AC Should be applied only when some conditions are met. We don't have the
% apd state here (or the temperature in many of the data scenes) so I set
% them here hard coded
humidityTemp = 40;
params.apdGain = 9;% should actually be the apd state
[params] = OnlineCalibration.aux.getParamsForAC(params,manualTrigger);

[validACConditions,dbg] = OnlineCalibration.aux.checkACConstrains(params.apdGain,humidityTemp,params);
if ~validACConditions
    return;
end

%%
originalParams = params;

% Save Inputs
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(frame.z),'uint16');
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(frame.i),'uint8');
%OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(frame.yuy2),'uint8');

% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy, frame.sectionMapRgb,  frame.sectionMapRgbEdges] = OnlineCalibration.aux.preprocessRGB(frame,params);

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_lum',frame.yuy2,'uint8');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',frame.rgbEdge,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',frame.rgbIDT,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',frame.rgbIDTx,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',frame.rgbIDTy,'double');

% Preprocess Z and IR
[frame.irEdge,frame.zEdge,frame.xim,frame.yim,frame.zValuesForSubEdges,frame.zGradInDirection,frame.dirPerPixel,frame.weights,frame.vertices,frame.sectionMapDepth,frame.relevantPixelsImage,validIREdgesSize,validPixelsSize] = OnlineCalibration.aux.preprocessDepth(frame,params,outputBinFilesPath);
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

%%
% LRS
md.n_edges = size(frame.weights,1);
md.n_valid_ir_edges = validIREdgesSize;
md.n_valid_pixels =  validPixelsSize;
md.n_relevant_pixels = sum(frame.relevantPixelsImage(:) == 1);

%% decisionParams from input scene
[~,validInputStruct,isMovement] = OnlineCalibration.aux.validScene(frame,params,outputBinFilesPath);
[validInputs,directionData,sceneResults.inputValidityDbg] = OnlineCalibration.aux.inputValidityChecks(frame,params);

if isMovement || ~validInputs
    return;
end
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);
md.is_scene_valid = ~isMovement && validInputs;

%% Set initial value for some variables that change between iterations
currentFrameCand = frame;
newParamsK2DSM = params;
newParamsK2DSMCand = params;
converged = false;
cycle = 1;

lastCost = decisionParams.initialCost;
dsmRegsCand = dsmRegs;
acDataIn = acData;
acDataCand = acData;


% [~,~,newParamsKzFromP] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand);
outputBinFilesPathStruct.cycle = cycle; 
outputBinFilesPathStruct.path = outputBinFilesPath;
[~,newParamsP,newParamsKzFromP,convergedReason] =  OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand,outputBinFilesPathStruct);
while ~converged && cycle-1 < params.maxK2DSMIters
    cycle = cycle + 1; 
    outputBinFilesPathStruct.cycle = cycle;
    %%
    % LRS deubug
    [cycleData] = prepareCycleData4LrsDebug(cycle,newParamsP,newParamsKzFromP,convergedReason,acData,dsmRegs);
    saveCycleData(outputBinFilesPath, cycleData); 
    %%
    % K2DSM
    [currentFrameCand,newParamsK2DSMCand,acDataCand,dsmRegsCand,inputs] = OnlineCalibration.K2DSM.convertNewK2DSM(frame,newParamsKzFromP,acData,dsmRegs,regs,params);
    %%
    % LRS deubug
    [KtoDsmData] = prepareK2dsmStruct4LrsDebug(dsmData,cycle,inputs,acDataCand,dsmRegsCand,currentFrameCand.vertices);
    saveKtoDsmData(outputBinFilesPath, KtoDsmData);
    %%
    % Optimize P
    [newCostCand,newParamsPCand,newParamsKzFromPCand,convergedReason] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand,outputBinFilesPathStruct);
    if newCostCand < lastCost
        % End iterations
        converged = 1;
        % No change at all (probably very good starting point)
        if cycle == 2
            newParamsK2DSM = params;
            newParamsP = params;
            sceneResults.newCost = lastCost;
        end
    else
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
p_matrix = newParamsK2DSM.rgbPmat';
f_name = 'end_p_matrix';  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, p_matrix(:)','double');
    
p_matrix = newParamsP.rgbPmat';
f_name = 'end_p_matrix_opt';  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, p_matrix(:)','double');

f_name = 'end_vertices';  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, frame.vertices,'double');
        
f_name = 'end_Kdepth';  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, newParamsKzFromPCand.Kdepth,'double');
        
new_calib = calibAndCostToRaw(newParamsK2DSM, newCost);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'new_calib',new_calib,'double');
%% Clip scaling movement
acData = OnlineCalibration.K2DSM.clipACScaling(acData,acDataIn,params.maxGlobalLosScalingStep);
%% Validate new parameters
[finalParams,dbg,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(frame,params,newParamsP,newParamsK2DSM,originalParams,params.iterFromStart);
% Merge all decision params
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct);
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validInputStruct);
decisionParams.newCost = newCost(end);


[validFixBySVM,~] = OnlineCalibration.aux.validBySVM(decisionParams,params,outputBinFilesPath);
validParams = validFixBySVM && (cycle > 2); 

if validParams
    params = finalParams;
end
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'costDiffPerSection',dbg.scoreDiffPersection,'double');
md.xy_movement = dbg.xyMovement;
md.is_output_valid = validParams;

%% Write the metadata:
fid = fopen( fullfile( outputBinFilesPath, 'metadata' ), 'w' );
fwrite( fid, md.xy_movement, 'double' );
fwrite( fid, md.n_edges, 'uint64' );
fwrite( fid, md.n_valid_ir_edges, 'uint64' );
fwrite( fid, md.n_valid_pixels, 'uint64' );
fwrite( fid, md.n_relevant_pixels, 'uint64' );
fwrite( fid, cycle, 'uint64' );
fwrite( fid, md.is_scene_valid, 'uint8' );
fwrite( fid, md.is_output_valid, 'uint8' );
fclose( fid );
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
end

function [cycleData] = prepareCycleData4LrsDebug(cycle,newParamsP,newParamsKzFromP,convergedReason,acData,dsmRegs)
cycleData.cycle = cycle;
cycleData.newParamsP = newParamsP;
cycleData.newParamsK2DSM = newParamsKzFromP;
cycleData.converged_resone = convergedReason;
cycleData.acData = acData;
cycleData.dsmRegs = dsmRegs;
end

function [KtoDsmData] = prepareK2dsmStruct4LrsDebug(dsmData,cycle,inputs,acDataCand,dsmRegsCand,vertices)
KtoDsmData = dsmData;
KtoDsmData.cycle = cycle;
KtoDsmData.inputs = inputs;
KtoDsmData.acDataCand = acDataCand;
KtoDsmData.dsmRegsCand = dsmRegsCand;
KtoDsmData.vertices = vertices;
end