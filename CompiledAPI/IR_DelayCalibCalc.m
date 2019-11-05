function [res, delayIR, im, pixVar] = IR_DelayCalibCalc(depthDataUp, depthDataDown, sz, delay, calibParams, isFinalStage, fResMirror)
% description: the function should run in loop till the delay is converged. 
%   single loop iteration see function IR_DelayCalib.m 
%   full IR delay see TODO:  
% inputs:
%   depthDataUp - up images (in binary sequence form)
%   depthDataDown - down images (in binary sequence form)
%       files format bin files naming I_0001 I_0002 ... 
%       NOTE:
%           - seprate dir for up/down
%           - NO extra bin files shoud be in the directory
%           - all images same resolution.
%   width     - image width.
%   hight     - image hight.
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
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_internal_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_delay_cnt g_LogFn g_countRuntime;
    unFiltered  = 0;

    % setting default global value in case not initial in the init function;
    if isempty(g_delay_cnt)
        g_delay_cnt = 0;
    else
        g_delay_cnt = g_delay_cnt+1; 
    end

    if isempty(g_debug_log_f)
        g_debug_log_f = 0;
    end
    if isempty(g_verbose)
        g_verbose = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_internal_input_flag)
        g_save_internal_input_flag = 0;
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

    imU = Calibration.aux.convertBinDataToFrames(depthDataUp, sz, true, 'depth');
    imD = Calibration.aux.convertBinDataToFrames(depthDataDown, sz, true, 'depth');
    imU = getFilteredImage(imU,unFiltered);
    imD = getFilteredImage(imD,unFiltered);

    if isFinalStage
        suffix = '_final';
    else
        suffix = '_init';
    end
        
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'depthDataUp', 'depthDataDown', 'sz', 'delay', 'calibParams', 'isFinalStage', 'fResMirror');
    end
    if g_save_internal_input_flag && exist(g_output_dir,'dir')~=0 
        dataDelayParams = calibParams.dataDelay;
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('_int%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'imU', 'imD', 'delay' ,'dataDelayParams', 'g_verbose', 'fResMirror', 'g_delay_cnt');
    end

    [res, delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imU, imD, delay, calibParams.dataDelay, g_verbose, fResMirror, g_delay_cnt); 
    
        % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir,  'mat_files' , [func_name sprintf('%s_out%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'res', 'delayIR', 'im', 'pixVar');
    end
    if(res~=0)
        g_delay_cnt = 0;
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nIR_DelayCalibCalc run time = %.1f[sec]\n', t1);
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
