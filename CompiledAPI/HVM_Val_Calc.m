function [valResults, allResults] = HVM_Val_Calc(frameBytes, sz, params, calibParams, valResults)
% function 
% description: 
%
% inputs:
%   frameBytes -  images (in bytes sequence form)
%   calibParams - calibparams strcture.
%   valResults - validation result strcture can be empty or with prev
%   running inoreder to accumate results
%                                  
%  output:
%   allResults - 
%   valResults - 
%   

    t0 = tic;
    global g_output_dir g_save_input_flag  g_save_output_flag  g_fprintff g_LogFn g_countRuntime; % g_regs g_luts;
    % setting default global value in case not initial in the init function;
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    
    func_name = dbstack;
    func_name = func_name(1).name;
    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir, func_name,'temp');
    else
        output_dir = g_output_dir;
    end
    
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end

    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,'mat_files' , [func_name '_in.mat']);
        save(fn,'frameBytes','sz','params','calibParams','valResults');
    end
    runParams.outputFolder = output_dir;
    [valResults, allResults] = HVM_Val_Calc_int(frameBytes, sz, params, runParams, calibParams, fprintff, valResults);

    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,'mat_files' , [func_name '_out.mat']);
        save(fn,'valResults', 'allResults');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nHVM_Val_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end




function [valResults ,allResults] = HVM_Val_Calc_int(frameBytes,sz,params,runParams,calibParams,fprintff,valResults)
    
%% get frames
    defaultDebug = 0;
    outFolder = fullfile(runParams.outputFolder,'Validation',[]);
    mkdirSafe(outFolder);
    debugMode = flip(dec2bin(uint16(defaultDebug),2)=='1');

%% load images
    im = Calibration.aux.convertBytesToFrames(frameBytes, sz, [], false);
    for i =1:1:size(im.i,3)
        frames(i).i = im.i(:,:,i);
        frames(i).z = im.z(:,:,i);
    end
    AvgIm.i = Calibration.aux.average_images(im.i);
    AvgIm.z = Calibration.aux.average_images(im.z);
    
%% DFZ
    Metrics = 'dfz';
    params.target.squareSize = calibParams.validationConfig.target.cbSquareSz;
    params.target.name = calibParams.validationConfig.target.name;
    params.expectedGridSize = calibParams.validationConfig.cbGridSz;
    params.sampleZFromWhiteCheckers = calibParams.validationConfig.sampleZFromWhiteCheckers;
    params.plainFitMaskIsRoiRect = calibParams.validationConfig.plainFitMaskIsRoiRect;
    params.gidMaskIsRoiRect = calibParams.validationConfig.gidMaskIsRoiRect;
    %average image 
    [dfzRes,allDfzRes,dbg] = Calibration.validation.DFZCalc(params,AvgIm,runParams,fprintff);
    valResults = Validation.aux.mergeResultStruct(valResults, dfzRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allDfzRes;
%% sharpness
    Metrics = 'sharpness';
    [~, allSharpRes,dbg] = Validation.metrics.gridEdgeSharp(frames, []);
    sharpRes.horizontalSharpness = allSharpRes.horizMean;
    sharpRes.verticalSharpness = allSharpRes.vertMean;
    valResults = Validation.aux.mergeResultStruct(valResults, sharpRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allSharpRes;
%% temporalNoise
    Metrics = 'temporalNoise';
    tempNConfig = calibParams.validationConfig.(Metrics);
    params = Validation.aux.defaultMetricsParams();
    params.(Metrics) = tempNConfig.roi;
    [tns,allTnsResults] = Validation.metrics.zStd(frames, params);
    tnsRes.temporalNoise = tns;
    valResults = Validation.aux.mergeResultStruct(valResults, tnsRes);
    saveValidationData(allTnsResults,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allTnsResults;
%% ROI
    Metrics = 'roi';
%    [roiRes, frames,dbg] = Calibration.validation.validateROI(hw,calibParams,fprintff);
    [roiRes ,dbg] = Calibration.validation.ROICalc(AvgIm,calibParams,fprintff);
    valResults = Validation.aux.mergeResultStruct(valResults, roiRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = roiRes;
%% LOS
    Metrics = 'los';
%    losConfig = calibParams.validationConfig.(Metrics);
%    [losRes,allLosResults,frames,dbg] = Calibration.validation.validateLOS(hw,runParams,losConfig,calibParams.validationConfig.cbGridSz,fprintff);
    [losRes,allLosResults,dbg] = Calibration.validation.LOSCalc(frames,runParams,calibParams.validationConfig.cbGridSz,fprintff);
    valResults = Validation.aux.mergeResultStruct(valResults, losRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
    allResults.HVM.(Metrics) = allLosResults;
end

function saveValidationData(debugData,frames,metric,outFolder,debugMode)
    
    % debug mode 1 indicates if we store the debug data of the metric
    if debugMode(1) && ~isempty(debugData)
        save(fullfile(outFolder,[metric '.mat']),'debugData');
    end
    
    % debug mode 2 indicates if we store the frames data of the metric
    if debugMode(2) && ~isempty(frames)
        f = fieldnames(frames);
        for i = 1:length(f)
            imfn = fullfile(dirname,strcat(metric,'Frame_',f{i},'.png'));
            imwrite(frames.(f{i}),imfn);
        end
    end
    
end
