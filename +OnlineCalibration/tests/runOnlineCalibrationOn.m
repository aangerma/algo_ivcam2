function runOnlineCalibrationOn(sceneDir,LRS)

outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images
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
startParams = params;

sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);

% Save Inputs
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(frame.z),'uint16');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(frame.i),'uint8');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(frame.yuy2),'uint8');

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
    frame.sectionMapDepth] = OnlineCalibration.aux.preprocessDepth(frame,params,sceneDir);
end

frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
md.n_edges = size(frame.weights,1);

%% Validate input scene
md.is_scene_valid = true;
if ~OnlineCalibration.aux.validScene(frame,params, sceneDir)
    disp('Scene not valid!');
    md.is_scene_valid = false;
     %return;
end

% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'depthEdgeWeightDistributionPerSectionDepth',validSceneStruct.edgeWeightDistributionPerSectionDepth,'double');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapDepth_trans',uint8(transpose(frames.sectionMapDepth)),'uint8');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightDistributionPerSectionRgb',validSceneStruct.edgeWeightDistributionPerSectionRgb,'double');
% OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'sectionMapRgb_trans',uint8(transpose(frames.sectionMapRgb)),'uint8');

%% Perform Optimization
%params.derivVar = 'KrgbRT';
params.derivVar = 'KrgbRTP';
[newParams, newCost, md.n_iter] = OnlineCalibration.Opt.optimizeParameters(frame,params,outputBinFilesPath);
% params.derivVar = 'P';
% newParamsP = OnlineCalibration.Opt.optimizeParametersP(frame,params);

new_calib = calibAndCostToRaw(newParams, newCost);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'new_calib',new_calib,'double');

%OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);
% % OnlineCalibration.Metrics.calcUVMappingErr(frame,newParamsP,1);
%OnlineCalibration.Metrics.calcUVMappingErr(frame,newParams,1);
%ax = gca;
%title({ax.Title.String;'New R,T,Krgb optimization'});
%% Validate new parameters
[validParams,updatedParams,dbg] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,startParams,1);
if validParams
    params = updatedParams;
end
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'costDiffPerSection',dbg.scoreDiffPersection,'double');
md.xy_movement = dbg.xyMovement;
md.is_output_valid = validParams;

%% Write the metadata:
fid = fopen( fullfile( outputBinFilesPath, 'metadata' ), 'w' );
fwrite( fid, md.xy_movement, 'double' );
fwrite( fid, md.n_edges, 'uint64' );
fwrite( fid, md.n_iter, 'uint64' );
fwrite( fid, md.is_scene_valid, 'uint8' );
fwrite( fid, md.is_output_valid, 'uint8' );
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