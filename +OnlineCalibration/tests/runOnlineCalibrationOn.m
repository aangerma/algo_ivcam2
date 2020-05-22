function runOnlineCalibrationOn(sceneDir,LRS)

outputBinFilesPath = fullfile(sceneDir,'binFiles\ac1x'); % Path for saving binary images
% Load data of scene 
% load(intrinsicsExtrinsicsPath);

disp('');
disp(sceneDir);

if LRS
    [camerasParams] = getCameraParamsRaw(sceneDir);
else
    [camerasParams] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir);
end 
saveCameraParamsRaw(outputBinFilesPath, camerasParams);
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
    
   saveDSMParamsRaw(outputBinFilesPath, binWithHeaders, acDataBin, calibDataBin, dsmRegs);
end
% Prepare AC table data for usage
[acData,regs,dsmRegs] = OnlineCalibration.K2DSM.parseCameraDataForK2DSM(dsmRegs,acDataBin,calibDataBin,binWithHeaders);

 
% frame = OnlineCalibration.aux.loadZIRGBFrames(imagesSubdir);
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir, LRS);

% If there's no previous frame, use the first frame (i.e., no movement)
n_yuys = size( frame.yuy_files, 1 );
if n_yuys < 2
    frame.yuy2Prev = frame.yuy2;
    frame.yuy_files(2) = frame.yuy_files(1);
else
    frame.yuy2Prev = frame.yuy2(:,:,2);
end

% Keep only the first frame of each
frame.z = frame.z(:,:,1);
frame.i = frame.i(:,:,1);
frame.yuy2 = frame.yuy2(:,:,1);

% Write the filenames out, so we can easily reproduce in C++
fid = fopen( fullfile( outputBinFilesPath, 'yuy_prev_z_i.files' ), 'wt' );
fprintf( fid, '%s\n%s\n%s\n%s', frame.yuy_files(1).name, frame.yuy_files(2).name, frame.z_files(1).name, frame.i_files(1).name );
fclose( fid );

% Fill a metadata struct and write it out at the end:
md = struct;

% Define hyperparameters

params = camerasParams;
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);

params.cbGridSz = [9,13];% not part of the optimization 
[params] = OnlineCalibration.aux.getParamsForAC(params);
%%
originalParams = params;
startParams = params;

sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);

% Save Inputs
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(frame.z),'uint16');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(frame.i),'uint8');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(frame.yuy2),'uint8');

% Preprocess RGB
[frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',double(frame.rgbEdge),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',frame.rgbIDT,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',frame.rgbIDTx,'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',frame.rgbIDTy,'double');

if  0
%     Old preprocessing
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

    sectionMapDepth_trans = transpose(sectionMapDepth);
    supressed_depth_t =  transpose(frame.zEdgeSupressed);
    sectionMapDepth_trans = sectionMapDepth_trans(supressed_depth_t>0);
    sectionMapRgb_trans = transpose(sectionMapRgb);
    supressed_rgb_t =  transpose(frame.rgbIDT);
    sectionMapRgb_trans = sectionMapRgb_trans(supressed_rgb_t>0);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapDepth_trans',uint8(sectionMapDepth_trans),'uint8');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapRgb_trans',uint8(sectionMapRgb_trans),'uint8');


    [frame.vertices] = OnlineCalibration.aux.subedges2vertices(frame,params);
    [frame.weights] = OnlineCalibration.aux.calculateWeights(frame,params);
    frame.sectionMapDepth = sampleByMask(sectionMapDepth,frame.zEdgeSupressed>0);
    frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',double(frame.vertices),'double');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weightsT',frame.weights,'double');
    
    
else
    [frame.irEdge,frame.zEdge,...
    frame.xim,frame.yim,frame.zValuesForSubEdges...
    ,frame.zGradInDirection,frame.dirPerPixel,frame.weights,frame.vertices,...
    frame.sectionMapDepth, validIREdgesSize,validPixelsSize,frame.relevantPixelsImage] = OnlineCalibration.aux.preprocessDepth(frame,params,outputBinFilesPath);

    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_xim',frame.xim,'double');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_yim',frame.yim,'double');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'zGradInDirection',frame.zGradInDirection,'double');
end

frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
md.n_edges = size(frame.weights,1);
md.n_valid_ir_edges = validIREdgesSize;
md.n_valid_pixels =  validPixelsSize;
% %% Validate input scene
% md.is_scene_valid = true;
% if ~OnlineCalibration.aux.validScene(frame,params, outputBinFilesPath)
%     disp('Scene not valid!');
%     md.is_scene_valid = false;
%      %return;
% end
%% decisionParams from input scene

[~,validInputStruct,isMovement] = OnlineCalibration.aux.validScene(frame,params,outputBinFilesPath);
decisionParams.initialCost = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);

md.is_scene_valid = ~isMovement;

% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'depthEdgeWeightDistributionPerSectionDepth',validSceneStruct.edgeWeightDistributionPerSectionDepth,'double');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapDepth_trans',uint8(transpose(frames.sectionMapDepth)),'uint8');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightDistributionPerSectionRgb',validSceneStruct.edgeWeightDistributionPerSectionRgb,'double');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapRgb_trans',uint8(transpose(frames.sectionMapRgb)),'uint8');

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


[~,~,newParamsKzFromP] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand,outputBinFilesPath);
while ~converged && iterNum < params.maxK2DSMIters
    % K2DSM
    [currentFrameCand,newParamsK2DSMCand,acDataCand,dsmRegsCand] = OnlineCalibration.K2DSM.convertNewK2DSM(outputBinFilesPath,frame,newParamsKzFromP,acData,dsmRegs,regs,params);
    % Optimize P
    [newCostCand,newParamsPCand,newParamsKzFromPCand] = OnlineCalibration.aux.optimizeP(currentFrameCand,newParamsK2DSMCand,outputBinFilesPath);
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
% [validParams,updatedParams,dbg] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,startParams,1);
% if validParams
%     params = updatedParams;
% end
%% Validate new parameters
[~,~,dbg,validOutputStruct] = OnlineCalibration.aux.validOutputParameters(frame,params,newParamsP,originalParams,params.iterFromStart);
% Merge all decision params
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validOutputStruct); 
decisionParams = Validation.aux.mergeResultStruct(decisionParams, validInputStruct); 
decisionParams.newCost = newCost(end);


[validFixBySVM,~] = OnlineCalibration.aux.validBySVM(decisionParams,params,outputBinFilesPath);
validParams = ~isMovement && validFixBySVM; 

if validParams
    params = newParamsK2DSM;
end
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'costDiffPerSection',dbg.scoreDiffPersection,'double');

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'costDiffPerSection',dbg.scoreDiffPersection,'double');
md.xy_movement = dbg.xyMovement;
md.is_output_valid = validParams;

%% Write the metadata:
fid = fopen( fullfile( outputBinFilesPath, 'metadata' ), 'w' );
%fwrite( fid, md.xy_movement, 'double' );
fwrite( fid, md.n_edges, 'uint64' );
fwrite( fid, md.n_valid_ir_edges, 'uint64' );
fwrite( fid, md.n_valid_pixels, 'uint64' );
fwrite( fid, iterNum, 'uint64' );
fwrite( fid, md.is_scene_valid, 'uint8' );
%fwrite( fid, md.is_output_valid, 'uint8' );
fclose( fid );

%% figure; 
% subplot(421); imagesc(frame.i); impixelinfo; title('IR image');colorbar;
% subplot(422); imagesc(frame.irEdge); impixelinfo; title('IR edge');colorbar;
% subplot(423);imagesc(frame.z./4); impixelinfo; title('Depth image');colorbar;
% subplot(424);imagesc(frame.zEdgeSupressed>0); impixelinfo; title('zEdgeSupressed image');colorbar;
% subplot(425);imagesc(frame.yuy2); impixelinfo; title('Color image');colorbar;
% subplot(426);imagesc(frame.rgbEdge); impixelinfo; title('Color edge');colorbar;
% subplot(427);imagesc(frame.rgbIDT); impixelinfo; title('Color IDT');colorbar;

end
