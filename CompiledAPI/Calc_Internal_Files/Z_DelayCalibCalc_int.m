function [res , delayZ, im] = Z_DelayCalibCalc_int(imU,imD,imB ,CurrentDelay, runParams, dataDelayParams, fResMirror, delay_cnt)
    nsEps       = 2;
    unFiltered  = 0;
    res = 0; %(WIP) not finish calibrate
    
    delayZ = calcDelayFromCorrelationDifference(imB, imU, imD, fResMirror);
    
    im=cat(3,imD,(imD+imU)/2,imU); % debug image
    if 1
        ff = Calibration.aux.invisibleFigure;
        imagesc(im);
        title(sprintf('Z delay: %d (%d)',CurrentDelay,delayZ));
        Calibration.aux.saveFigureAsImage(ff,runParams,'DataDelay','Z up-down match',1);
    end
   
    % check convergence
    if (abs(delayZ)<=dataDelayParams.iterFixThr)        % delay calibration converege 
        res = 1;                                       
        clear Z_DelayCalibCalc;
    elseif (delay_cnt>1 && abs(delayZ)-nsEps > abs(CurrentDelay))  
         res = -1;                                       % not converging delay calibration converege 
        warning('delay not converging!');
        clear Z_DelayCalibCalc;
    end
    delayZ = CurrentDelay + delayZ;
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function peak = findPeak(i1, i2, i3)
    d1 = i2 - i1;
    d2 = i3 - i2;
    peak = d1 / (d1 - d2) + 0.5;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function delayZ = calcDelayFromCorrelationDifference(ir, imU, imD, fResMirror)
    [t, xLims, yLims] = Calibration.dataDelay.genMapSphericalPixel2Time(ir, fResMirror);
    % eliminating NaN's
    ir(isnan(ir)) = 0;
    imU(isnan(imU)) = 0;
    imD(isnan(imD)) = 0;
    % vertical derivatives (with W->B transient artifact eliminated)
    dImU_neg = min(0, diff(imU)); % image suffers from artifact downwards - ignore positive changes 
    dImD_pos = max(0, diff(imD)); % image suffers from artifact upwards - ignore negative changes
    dIR = diff(ir);
    dIR_neg = min(0, dIR); % for correlating with up image derivative
    dIR_pos = max(0, dIR); % for correlating with down image derivative
    [nPixY, nPixX] = size(dIR);
    % resampling in linear time
    linT = linspace(1e-6, 23e-6, nPixY); %TODO: derive lims as a function of freq
    dImU_neg_res = NaN(nPixY, nPixX);
    dImD_pos_res = NaN(nPixY, nPixX);
    dIR_neg_res = NaN(nPixY, nPixX);
    dIR_pos_res = NaN(nPixY, nPixX);
    for x = xLims(1):xLims(2)
        idcs = find( ((1:nPixY) > yLims{1}(x)) & ((1:nPixY) < yLims{2}(x)) );
        dImU_neg_res(:,x) = interp1(t(x,idcs), dImU_neg(idcs,x), linT);
        dImD_pos_res(:,x) = interp1(t(x,idcs), dImD_pos(idcs,x), linT);
        dIR_neg_res(:,x) = interp1(t(x,idcs), dIR_neg(idcs,x), linT);
        dIR_pos_res(:,x) = interp1(t(x,idcs), dIR_pos(idcs,x), linT);
    end
    dImU_neg_res = dImU_neg_res(:, xLims(1):xLims(2));
    dImD_pos_res = dImD_pos_res(:, xLims(1):xLims(2));
    dIR_neg_res = dIR_neg_res(:, xLims(1):xLims(2));
    dIR_pos_res = dIR_pos_res(:, xLims(1):xLims(2));
    % correlations
    ns = 15; % search range (about +-700nsec, well beyond empirically observed uncertainty)
    corr1 = conv2(dIR_pos_res, rot90(dImD_pos_res(ns+1:end-ns,:),2), 'valid');
    corr2 = conv2(dIR_neg_res, rot90(dImU_neg_res(ns+1:end-ns,:),2), 'valid');  
    % validity check
    peaks1 = sort(findpeaks(corr1), 'descend');
    peaks2 = sort(findpeaks(corr2), 'descend');
    if isempty(peaks1) || ( (length(peaks1)>1) && (peaks1(2)/peaks1(1)>0.5) )
        error('%s: Inconclusive delay in search region (image probably does not match input delay)', 'Z delay down image')
    end
    if isempty(peaks2) || ( (length(peaks2)>1) && (peaks2(2)/peaks2(1)>0.5) )
        error('%s: Inconclusive delay in search region (image probably does not match input delay)', 'Z delay up image')
    end
    % peak estimation
    [~,iMax1] = max(corr1);
    [~,iMax2] = max(corr2);
    peak1 = iMax1 + findPeak(corr1(iMax1-1), corr1(iMax1), corr1(iMax1+1));
    peak2 = iMax2 + findPeak(corr2(iMax2-1), corr2(iMax2), corr2(iMax2+1));
    % delay calculation
    delayZ = int32(1e9*(interp1(1:nPixY,linT,peak2)-interp1(1:nPixY,linT,peak1))/2);
end