function [valResults ,allResults] = HVM_Val_Coverage_Calc(InputPath, sz, calibParams, valResults)
% function 
% description: 
%
% inputs:
%   InputPath -  path for input images  dir stucture InputPath
%        note 
%           I image naming I_*_000n.bin
%   calibParams - calibparams strcture.
%   valResults - validation result strcture can be empty or with prev
%   running inoreder to accumate results
%                                  
%  output:
%   allResults - 
%   valResults - 
%   

    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn; % g_regs g_luts;
    % setting default global value in case not initial in the init function;
    if isempty(g_debug_log_f)
        g_debug_log_f = 0;
    end
    if isempty(g_verbose)
        g_verbose = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_dummy_output_flag)
        g_dummy_output_flag = 0;
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
        save(fn, 'InputPath', 'sz', 'calibParams', 'valResults');
    end
    runParams.outputFolder = output_dir;
    [valResults ,allResults] = HVM_Val_Coverage_Calc_int(InputPath,sz,runParams,calibParams,fprintff,valResults);

    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files', [func_name '_out.mat']);
        save(fn, 'valResults', 'allResults');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

function [valResults ,allCovRes] = HVM_Val_Coverage_Calc_int(InputPath,sz,runParams,calibParams,fprintff,valResults)
    width = sz(2);
    height = sz(1);
    defaultDebug = 0;
    outFolder = fullfile(runParams.outputFolder,'Validation',[]);
    mkdirSafe(outFolder);
    debugMode = flip(dec2bin(uint16(defaultDebug),2)=='1');

%% load images
    im.i = Calibration.aux.GetFramesFromDir(InputPath,width, height,'I');
    
    for i =1:1:size(im.i,3)
        frames(i).i = im.i(:,:,i);
    end

    fn = fullfile(runParams.outputFolder, 'mat_files',  'Coverage_out.mat');
    save(fn,'frames');
    
    Metrics = 'coverage';
%    covConfig = calibParams.validationConfig.(Metrics);
    %calculate ir coverage metric
    [covScore,allCovRes, dbg] = Validation.metrics.irCoverage(frames);
    dbg.probIm;
    covRes.irCoverage = covScore;
    fprintff('ir Coverage:  %2.2g\n',covScore);
    valResults = Validation.aux.mergeResultStruct(valResults, covRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
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
