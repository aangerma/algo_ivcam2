function [res , delayIR, im ,pixVar] = IR_DelayCalibCalc(path_up, path_down, width , hight , delay ,calibParams)
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
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprinff;
    fprintff = g_fprinff;
    
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

    imUs_i = Calibration.aux.GetFramesFromDir(path_up   ,width , hight);
    imDs_i = Calibration.aux.GetFramesFromDir(path_down ,width , hight);
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, [func_name '_in.mat']);
        save(fn,'imUs_i', 'imDs_i' , 'width' , 'hight' , 'delay');
    end

    [res, delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imUs_i,imDs_i, delay , calibParams.dataDelay, g_verbose); 
    
        % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, [func_name '_out.mat']);
        save(fn,'res', 'delayIR', 'im' , 'pixVar');
    end
end


function [res , delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imUs_i,imDs_i, CurrentDelay, dataDelayParams ,verbose)
    persistent n
    nsEps       = 2;
    unFiltered  = 0;

    if isempty(n)
        n = 0;
    end
    n = n + 1;
    
    res = 0; %(WIP) not finish calibrate
    
    nomMirroFreq = 20e3;
% average I image
    imU_i = average_image(imUs_i);
    imD_i = average_image(imDs_i);
% w/o filter getting I image only 
    imU=getFilteredImage(imU_i,unFiltered);
    imD=getFilteredImage(imD_i,unFiltered);
% debug image
    im=cat(3,imD,(imD+imU)/2,imU);          % debug

% estimate delay    
    t=@(px)acos(-(px/size(imD,1)*2-1))/(2*pi*nomMirroFreq);
    
    rotateBy180 = 1;
    p1 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imD, rotateBy180);
    p2 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imU, rotateBy180);
    if ~isempty(p1(~isnan(p1))) && ~isempty(p2(~isnan(p2)))
       
        delayIR = round(nanmean(vec(t(p1(:,:,2))-t(p2(:,:,2))))/2*1e9);
        diff = p1(:,:,2)-p2(:,:,2);
        diff = diff(~isnan(diff));
        pixVar = var(diff);
    end
    
    if (isnan(delayIR))                         %CB was not found, throw delay forward to find a good location
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
        clear IR_DelayCalibCalc;
    elseif (n>1 && abs(delayIR)-nsEps > abs(CurrentDelay))  
         res = -1;                                       % not converging delay calibration converege 
        warning('delay not converging!');
        clear IR_DelayCalibCalc;
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
