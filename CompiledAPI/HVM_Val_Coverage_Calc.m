function [valResults, allResults] = HVM_Val_Coverage_Calc(frameBytes, sz, calibParams, valResults)
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
    global g_output_dir g_save_input_flag g_save_output_flag g_fprintff g_LogFn g_countRuntime;
    
    % auto-completions
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);

    % input save
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytes', 'sz', 'runParams', 'calibParams', 'fprintff', 'valResults');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    [valResults, allResults] = HVM_Val_Coverage_Calc_int(frameBytes, sz, runParams, calibParams, fprintff, valResults);

    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files', [func_name '_out.mat']);
        save(fn, 'valResults', 'allResults');
    end
    
    % finalization
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\n%s run time = %.1f[sec]\n', func_name, t1);
    end
    if (fid>-1)
        fclose(fid);
    end
end

