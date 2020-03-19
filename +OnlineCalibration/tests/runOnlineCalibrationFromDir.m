function [] = runOnlineCalibrationFromDir(sceneDir,params)
global sceneResults;
sceneResults = struct;
sceneResults.sceneFullPath = sceneDir;
outputBinFilesPath = fullfile(sceneDir,'binFiles'); % Path for saving binary images

[params] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneDir,params);
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);

params.moveThreshPixNum =  3e-05*prod(params.rgbRes);
originalParams = params;
sceneResults.originalParams = originalParams;
% imagesSubdir = fullfile(sceneDir,'ZIRGB');
% frame = OnlineCalibration.aux.loadZIRGBFrames(imagesSubdir);
frame = OnlineCalibration.aux.loadZIRGBFrames(sceneDir);

numImages = min([size(frame.yuy2,3),size(frame.z,3),size(frame.i,3)]);
if numImages < 2
    disp(['Not enough RGB frames in: ' num2str(sceneDir)]);
    if numImages == 1
        disp('Duplicating RGB image');
        frame.z(:,:,2) = frame.z(:,:,1);frame.i(:,:,2) = frame.i(:,:,1);frame.yuy2(:,:,2) = frame.yuy2(:,:,1);
        numImages = 2;
    else
        return;
    end
end
currentFrame.yuy2Prev = frame.yuy2(:,:,1);
for k = 2:numImages
    currentFrame.z = frame.z(:,:,k);
    currentFrame.i = frame.i(:,:,k);
    currentFrame.yuy2 = frame.yuy2(:,:,k);
    % Save Inputs
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_input',uint16(currentFrame.z),'uint16');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_input',uint8(currentFrame.i),'uint8');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_input',uint8(currentFrame.yuy2),'uint8');
    
    % Preprocess RGB
    [currentFrame.rgbEdge, currentFrame.rgbIDT, currentFrame.rgbIDTx, currentFrame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(currentFrame,params);
    sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
    currentFrame.sectionMapRgb = sectionMapRgb(currentFrame.rgbIDT>0);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_edge',single(currentFrame.rgbEdge),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDT',single(currentFrame.rgbIDT),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTx',single(currentFrame.rgbIDTx),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'YUY2_IDTy',single(currentFrame.rgbIDTy),'single');
    
    % Preprocess IR
    [currentFrame.irEdge] = OnlineCalibration.aux.preprocessIR(currentFrame,params);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'I_edge',single(currentFrame.irEdge),'single');
    
    % Preprocess Z
    % [currentFrame.zEdge,currentFrame.zEdgeSupressed,currentFrame.zEdgeSubPixel,currentFrame.zValuesForSubEdges,frame.dirI] = OnlineCalibration.aux.preprocessZ(currentFrame,params);
    [currentFrame.zEdge,currentFrame.zEdgeSupressed,currentFrame.zEdgeSubPixel,currentFrame.zValuesForSubEdges,currentFrame.dirI] = OnlineCalibration.aux.preprocessZAndIR(currentFrame,params);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edge',single(currentFrame.zEdge),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSubPixel',single(currentFrame.zEdgeSubPixel),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_edgeSupressed',single(currentFrame.zEdgeSupressed),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'Z_valuesForSubEdges',single(currentFrame.zValuesForSubEdges),'single');
    
    
    [currentFrame.vertices] = OnlineCalibration.aux.subedges2vertices(currentFrame,params);
    [currentFrame.weights] = OnlineCalibration.aux.calculateWeights(currentFrame,params);
    sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
    currentFrame.sectionMapDepth = sectionMapDepth(currentFrame.zEdgeSupressed>0);
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'vertices',single(currentFrame.vertices),'single');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'weights',single(currentFrame.weights),'single');
    
    
    if ~OnlineCalibration.aux.validScene(currentFrame,params)
        disp('Scene not valid!');
        if ~OnlineCalibration.Globals.getIgnoreSceneInvalidationFlag
            continue;
        end
    end
    %% Perform Optimization
    params.derivVar = 'KrgbRT';
    newParams = OnlineCalibration.Opt.optimizeParameters(currentFrame,params);
    params.derivVar = 'P';
    newParamsP = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params);
    
    [validParams,newParamsFixed,dbg] = OnlineCalibration.aux.validOutputParameters(currentFrame,params,newParams,originalParams,k);
    if ~OnlineCalibration.Globals.getIgnoreOutputValidationFlag()
        if validParams 
            newParams = newParamsFixed;
        else
            currentFrame.yuy2Prev = currentFrame.yuy2;
            continue;
        end
    end
    %
    try
        
        sceneResults.uvErrPre = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,originalParams,1);
        sceneResults.uvErrPostPOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParamsP,1);
        sceneResults.uvErrPostKRTOpt = OnlineCalibration.Metrics.calcUVMappingErr(currentFrame,newParams,1);
        ax = gca;
        title({sceneDir;ax.Title.String;'New R,T,Krgb optimization'});
    catch e
        sceneResults.errorMessage = e.message;
        sceneResults.uvErrPre = inf;
        sceneResults.uvErrPostPOpt = inf;
        sceneResults.uvErrPostKRTOpt = inf;
        disp([e.identifier ' '  e.message 'in ' sceneDir ', continuing to next image...']);
        
    end
    
    % figure;
    % subplot(421); imagesc(currentFrame.i); impixelinfo; title('IR image');colorbar;
    % subplot(422); imagesc(currentFrame.irEdge); impixelinfo; title('IR edge');colorbar;
    % subplot(423);imagesc(currentFrame.z./4); impixelinfo; title('Depth image');colorbar;
    % subplot(424);imagesc(currentFrame.zEdgeSupressed>0); impixelinfo; title('zEdgeSupressed image');colorbar;
    % subplot(425);imagesc(currentFrame.yuy2); impixelinfo; title('Color image');colorbar;
    % subplot(426);imagesc(currentFrame.rgbEdge); impixelinfo; title('Color edge');colorbar;
    % subplot(427);imagesc(currentFrame.rgbIDT); impixelinfo; title('Color IDT');colorbar;
    params = newParams;
    currentFrame.yuy2Prev = currentFrame.yuy2;
end
end

