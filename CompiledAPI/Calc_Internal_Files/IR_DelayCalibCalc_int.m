function [res , delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imU,imD, CurrentDelay, dataDelayParams ,fResMirror, delay_cnt)
    res = 0; %(WIP) not finish calibrate
    nsEps       = 2;
    
    % estimate delay
    rotateBy180 = 1;
    p1 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imD, rotateBy180, [], [], [], true);
    p2 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imU, rotateBy180, [], [], [], true);
    if ~isempty(p1(~isnan(p1))) && ~isempty(p2(~isnan(p2)))
        t = Calibration.dataDelay.genMapSphericalPixel2Time(imD, fResMirror);
        delayIR = round(nanmean(vec(t(p1(:,:,1),p1(:,:,2)) - t(p2(:,:,1),p2(:,:,2))))/2 * 1e9); % [nsec]
        diff = p1(:,:,2)-p2(:,:,2);
        diff = diff(~isnan(diff));
        pixVar = var(diff);
    else
        pixVar = NaN;
    end
    
    if (~exist('delayIR','var')) %CB was not found, throw delay forward to find a good location
        delayIR = 3000;
    end
    
    im=cat(3,imD,(imD+imU)/2,imU); % debug image
    if (0)
        figure(sum(mfilename));
        imagesc(im);
        title(sprintf('IR delay: %d (%d)',CurrentDelay,delayIR));
        drawnow;
    end
   
    % check convergence
    if (abs(delayIR)<=dataDelayParams.iterFixThr) % delay calibration converege 
        res = 1;                                       
    elseif (delay_cnt>1 && abs(delayIR)-nsEps > abs(CurrentDelay))  
        res = -1; % not converging delay calibration converege 
        warning('delay not converging!');
    end
    delayIR = CurrentDelay + delayIR;
end 