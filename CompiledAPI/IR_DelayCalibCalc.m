function [res, delayIR, im, pixVar] = IR_DelayCalibCalc(frameBytesUp, frameBytesDown, sz, delay, calibParams, isFinalStage, fResMirror)
% description: the function should run in loop till the delay is converged. 
%   single loop iteration see function IR_DelayCalib.m 
%   full IR delay see TODO:  
% inputs:
%   frameBytesUp - up images (in bytes sequence form)
%   frameBytesDown - down images (in bytes sequence form)
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
    global g_output_dir g_save_input_flag g_save_internal_input_flag g_save_output_flag g_fprintff g_delay_cnt g_LogFn g_countRuntime;
    unFiltered  = 0;

    % auto-completions
    if isempty(g_delay_cnt)
        g_delay_cnt = 0;
    else
        g_delay_cnt = g_delay_cnt+1; 
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
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);
    
    % input save
    if isFinalStage
        suffix = '_final';
    else
        suffix = '_init';
    end
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'frameBytesUp', 'frameBytesDown', 'sz', 'delay', 'calibParams', 'isFinalStage', 'fResMirror');
    end
    
    % operation
    imU = Calibration.aux.convertBytesToFrames(frameBytesUp, sz, [], true).i;
    imD = Calibration.aux.convertBytesToFrames(frameBytesDown, sz, [], true).i;
    imU = getFilteredImage(imU,unFiltered);
    imD = getFilteredImage(imD,unFiltered);
    dataDelayParams = calibParams.dataDelay;
    runParams.outputFolder = output_dir;
    
    if g_save_internal_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('_int%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'imU', 'imD', 'delay', 'runParams', 'dataDelayParams', 'fResMirror', 'g_delay_cnt');
    end
    [res, delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imU, imD, delay, runParams, dataDelayParams, fResMirror, g_delay_cnt); 
    
    % output save
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir,  'mat_files' , [func_name sprintf('%s_out%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'res', 'delayIR', 'im', 'pixVar');
    end
    if(res~=0)
        g_delay_cnt = 0;
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
