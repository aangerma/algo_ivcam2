function [res, delayZ, im] = Z_DelayCalibCalc(path_up, path_down, path_both, sz, delay, calibParams, isFinalStage)
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


    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_delay_cnt g_LogFn;

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

    % average I image
    imU_z = average_image(imUs_z);
    imD_z = average_image(imDs_z);
    imB_i = average_image(imBs_i);
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
        save(fn, 'path_up', 'path_down', 'path_both' , 'sz', 'delay', 'calibParams', 'isFinalStage');
        dataDelayParams = calibParams.dataDelay;
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('_int%s_in%d.mat',suffix,g_delay_cnt)]);
        save(fn,'imU', 'imD', 'imB', 'delay', 'dataDelayParams', 'g_verbose');
    end
    [res, delayZ, im ] = Z_DelayCalibCalc_int(imU, imD, imB , delay, calibParams.dataDelay, g_verbose); 
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
end

function [res , delayZ, im] = Z_DelayCalibCalc_int(imU,imD,imB ,CurrentDelay, dataDelayParams ,verbose)
    global g_delay_cnt;
    n = g_delay_cnt;
    nsEps       = 2;
    unFiltered  = 0;

    res = 0; %(WIP) not finish calibrate
    
% debug image
   
    delayPx = findCoarseDelay(imB, imU, imD);
    % time per pixel in spherical coordinates
    delayZ = int32(round(25*10^3*delayPx/size(imB,1)/2));
    
    im=cat(3,imD,(imD+imU)/2,imU);

    if (verbose)
        figure(sum(mfilename));
        imagesc(im);
        title(sprintf('Z delay: %d (%d)',CurrentDelay,delayZ));
        drawnow;
    end
   
% check convergence
    if (abs(delayZ)<=dataDelayParams.iterFixThr)        % delay calibration converege 
        res = 1;                                       
        clear Z_DelayCalibCalc;
    elseif (n>1 && abs(delayZ)-nsEps > abs(CurrentDelay))  
         res = -1;                                       % not converging delay calibration converege 
        warning('delay not converging!');
        clear Z_DelayCalibCalc;
    end
    
    delayZ = CurrentDelay + delayZ;
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



function delayInPx = findCoarseDelay(ir, alt1, alt2)

ir(isnan(ir)) = 0;
alt1(isnan(alt1)) = 0;
alt2(isnan(alt2)) = 0;


dir = diff(ir);
da1 = diff(alt1);
da2 = diff(alt2);

%% sigmoid kernel gradient
%{
kerLen = 3;
kerEdge = 1./(1+exp((-kerLen:kerLen)*1.5))-0.5;
%figure; plot(kerEdge)

dir = conv2(ir, kerEdge', 'valid');
da1 = conv2(a1, kerEdge', 'valid');
da2 = conv2(a2, kerEdge', 'valid');
%}

%% positive and negative gradients
% CRY = 100:380; % cropped range
% CRX = 50:500; % cropped range
% 
% dir_p = dir(CRY,CRX);
dir_p = dir;
dir_p(dir_p < 0) = 0;
% dir_n = dir(CRY,CRX);
dir_n = dir;
dir_n(dir_p > 0) = 0;


% da1_n = da1(CRY,CRX);
da1_n = da1;
da1_n(da1_n > 0) = 0;

% da2_p = da2(CRY,CRX);
da2_p = da2;
da2_p(da2_p < 0) = 0;


%% correlation

ns = 15; % search range

corr1 = conv2(dir_p, rot90(da2_p(ns+1:end-ns,:),2), 'valid');
corr2 = conv2(dir_n, rot90(da1_n(ns+1:end-ns,:),2), 'valid');
%figure; plot([corr1 flipud(corr2)]); title (sprintf('delay: %g', iFrame));

[~,iMax1] = max(corr1);
[~,iMax2] = max(corr2);

%delayInPx = iMax2 - iMax1;

peak1 = iMax1 + findPeak(corr1(iMax1-1), corr1(iMax1), corr1(iMax1+1));
peak2 = iMax2 + findPeak(corr2(iMax2-1), corr2(iMax2), corr2(iMax2+1));

delayInPx = (peak2 - peak1) / 2;




end

function peak = findPeak(i1, i2, i3)
d1 = i2 - i1;
d2 = i3 - i2;
peak = d1 / (d1 - d2) + 0.5;
end
