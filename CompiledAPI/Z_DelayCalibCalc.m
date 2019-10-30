function [res, delayZ, im] = Z_DelayCalibCalc(path_up, path_down, path_both, sz, delay, calibParams, isFinalStage, fResMirror)
% description: the function should run in loop till the delay is converged. 
%   single loop iteration see function IR_DelayCalib.m 
%   full IR delay see TODO:  
% inputs:
%   path_up   - path to scan up images. 
%   path_down - path to scan down images.  
%   path_both - path to scan down images.  
%       files format bin files naming I_0001 I_0002 ... 
%       NOTE:
%           - seprate dir for up/down
%           - NO extra bin files shoud be in the directory
%           - all images same resolution.
%   sz     - image hight,width.
%   delay     - the delay value that the images was taken (first round (initial value, 2nd etc the valus is come from the pre iteration. 
% output:
%   res       - <0>   -> not finish need another iteration
%             - <1>   -> finish success (delay convergence.
%             - <-1>  -> not converged
%   
%   delayIR   - found delay.
%   im        - combine up and down images (debug - visualized diff between
%               up / down scan images
%   pixVar    - delay variance.
%

    t0 = tic;
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_delay_cnt g_LogFn g_countRuntime;

    unFiltered  = 0;
     if isempty(g_delay_cnt)
        g_delay_cnt = 0;
    else
        g_delay_cnt = g_delay_cnt+1; 
    end
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

    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(g_output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(g_output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end

    
    width = sz(2);
    height = sz(1);
    imUs_z = Calibration.aux.GetFramesFromDir(path_up   ,width , height);
    imDs_z = Calibration.aux.GetFramesFromDir(path_down ,width , height);
    imBs_i = Calibration.aux.GetFramesFromDir(path_both ,width , height);
% w/o filter getting I image only 
    imU=getFilteredImage(imU_z,unFiltered);
    imD=getFilteredImage(imD_z,unFiltered);
    imB=getFilteredImage(imB_i,unFiltered);

    
    
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        if isFinalStage
            suffix = '_final';
        else
            suffix = '_init';
        end
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'path_up', 'path_down', 'path_both' , 'sz', 'delay', 'calibParams', 'isFinalStage', 'fResMirror');
        dataDelayParams = calibParams.dataDelay;
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('_int%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn,'imU', 'imD', 'imB', 'delay', 'dataDelayParams', 'g_verbose', 'fResMirror', 'g_delay_cnt');
    end
    [res, delayZ, im] = Z_DelayCalibCalc_int(imU, imD, imB , delay, calibParams.dataDelay, g_verbose, fResMirror, g_delay_cnt); 
        % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        if isFinalStage
            suffix = '_final';
        else
            suffix = '_init';
        end
        fn = fullfile(g_output_dir, 'mat_files' , [func_name sprintf('%s_out%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'res', 'delayZ', 'im');
    end
    if(res~=0)
        g_delay_cnt = 0;
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nZ_DelayCalibCalc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imo=getFilteredImage(d,unFiltered)
    im=double(d);
    if ~unFiltered
        im(im==0)=nan;
        imv=im(Utils.indx2col(size(im),[5 5]));
        imo=reshape(nanmedian_(imv),size(im));
    end
    imo=normByMax(imo);
end

