function [res , delayIR, im ,pixVar] = IR_DelayCalibCalc_int(imU,imD, CurrentDelay, runParams, dataDelayParams ,fResMirror, delay_cnt)
    res = 0; %(WIP) not finish calibrate
    nsEps       = 2;
    
    % estimate delay
    rotateBy180 = 1;
    p1 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imD, rotateBy180, [], [], [], true);
    p2 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imU, rotateBy180, [], [], [], true);
    if all(isnan(p1(:)))
        Calibration.aux.CBTools.interpretFailedCBDetection(imD, 'IR delay down image');
    end
    if all(isnan(p2(:)))
        Calibration.aux.CBTools.interpretFailedCBDetection(imU, 'IR delay up image');
    end
    t = Calibration.dataDelay.genMapSphericalPixel2Time(imD, fResMirror);
    delayIR = round(nanmean(vec(t(p1(:,:,1),p1(:,:,2)) - t(p2(:,:,1),p2(:,:,2))))/2 * 1e9); % [nsec]
    diff = p1(:,:,2)-p2(:,:,2);
    diff = diff(~isnan(diff));
    pixVar = var(diff);
    
    im=cat(3,imD,(imD+imU)/2,imU); % debug image
    if 1
        ff = Calibration.aux.invisibleFigure;
        imagesc(im);
        title(sprintf('IR delay: %d (%d)',CurrentDelay,delayIR));
        Calibration.aux.saveFigureAsImage(ff,runParams,'DataDelay','IR up-down match',1);
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