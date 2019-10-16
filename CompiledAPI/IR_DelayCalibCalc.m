function [res, delayIR, im, pixVar] = IR_DelayCalibCalc(path_up, path_down, sz, delay, calibParams, isFinalStage)
% description: the function should run in loop till the delay is converged. 
%   single loop iteration see function IR_DelayCalib.m 
%   full IR delay see TODO:  
% inputs:
%   path_up   - path to scan up images. 
%   path_down - path to scan down images.  
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
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_delay_cnt g_LogFn g_countRuntime;
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
    imUs_i = Calibration.aux.GetFramesFromDir(path_up   ,width , height);
    imDs_i = Calibration.aux.GetFramesFromDir(path_down ,width , height);
    % average I image
    imU_i = average_image(imUs_i);
    imD_i = average_image(imDs_i);
% w/o filter getting I image only 
    imU=getFilteredImage(imU_i,unFiltered);
    imD=getFilteredImage(imD_i,unFiltered);

        % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        if isFinalStage
            suffix = '_final';
        else
            suffix = '_init';
        end
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'path_up', 'path_down', 'sz', 'delay', 'calibParams', 'isFinalStage');
        dataDelayParams = calibParams.dataDelay;
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('_int%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn, 'imU', 'imD', 'delay' ,'dataDelayParams', 'g_verbose');
    end

    [res, delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imU, imD, delay, calibParams.dataDelay, g_verbose); 
    
        % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        if isFinalStage
            suffix = '_final';
        else
            suffix = '_init';
        end
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
end


function [res , delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imU,imD, CurrentDelay, dataDelayParams ,verbose)
    global g_delay_cnt;
    n = g_delay_cnt;
    res = 0; %(WIP) not finish calibrate
    nsEps       = 2;
    
    nomMirroFreq = 20e3;
% debug image
    im=cat(3,imD,(imD+imU)/2,imU);          % debug

% estimate delay    
    t=@(px)acos(-(px/size(imD,1)*2-1))/(2*pi*nomMirroFreq);
    
    rotateBy180 = 1;
    p1 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imD, rotateBy180, [], [], [], true);
    p2 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imU, rotateBy180, [], [], [], true);
    if ~isempty(p1(~isnan(p1))) && ~isempty(p2(~isnan(p2)))
       
        delayIR = round(nanmean(vec(t(p1(:,:,2))-t(p2(:,:,2))))/2*1e9);
        diff = p1(:,:,2)-p2(:,:,2);
        diff = diff(~isnan(diff));
        pixVar = var(diff);
    else
        pixVar = NaN;
    end
    
    if (~exist('delayIR','var'))                         %CB was not found, throw delay forward to find a good location
        delayIR = 3000;
    end
    if (verbose)
        figure(sum(mfilename));
        imagesc(im);
        title(sprintf('IR delay: %d (%d)',CurrentDelay,delayIR));
        drawnow;
    end
   
% check convergence
    if (abs(delayIR)<=dataDelayParams.iterFixThr)        % delay calibration converege 
        res = 1;                                       
    elseif (n>1 && abs(delayIR)-nsEps > abs(CurrentDelay))  
        res = -1;                                       % not converging delay calibration converege 
        warning('delay not converging!');
    end
    delayIR = CurrentDelay + delayIR;
end 


function [IM_avg] = average_image(stream) 
    IM_avg = sum(double(stream),3)./sum(stream~=0,3);
end

function imo=getFilteredImage(d,unFiltered)
    im=double(d);
    if ~unFiltered
        im(im==0)=nan;
        imv=im(Utils.indx2col(size(im),[5 5]));
        imo=reshape(nanmedian_(imv),size(im));
    end
    imo=normByMax(imo);
end
