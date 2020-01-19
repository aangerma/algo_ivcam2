function [results, data] = HVM_Val_RelativeErrors_Calc(frameBytes, sz, params, distanceVector)
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
    global g_output_dir g_save_input_flag g_save_output_flag g_countRuntime g_fprintff g_LogFn;
    
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
    
    runParams.outputFolder = output_dir;
    % input save
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytes', 'sz', 'params','distanceVector','runParams');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    [results, data] = HVM_Val_RelativeErrors_Calc_int(frameBytes, sz, params, runParams,distanceVector);

    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,'mat_files' , [func_name '_out.mat']);
        save(fn, 'results', 'data');
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


