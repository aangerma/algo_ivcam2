function [r,dtheta,snr] = testLIDARsim_cos(inputRange,p,systemOffset)
    ADC_MAX=1200;
    ADC_NBITS=2;

    
    
    if ~exist('p','var')
        p = xml2structWrapper('\\invcam322\ohad\data\lidar\simulatorParams\params_860SKU1_indoor.xml');
    end
    

    p.Comparator.riseTime = 0;
    w = 2*pi*p.laser.frequency;
    
    p.laser.txSequence = @(t) (1+cos(w*t))/2;
    p.verbose=0;
    nMes = 30;
    p.runTime= (length(p.laser.txSequence)/p.laser.frequency)*(10+nMes);
    
    
    p.verbose=0;
    p.measurmentStageType = 'scope';

    model =struct('t',[0 p.runTime],'r',[ inputRange  inputRange],'a',[ 1  1 ]);
    
    p.postTIAfiler.freq = p.laser.frequency +[-.5 +.5]*30e-3;
    p.postTIAfiler.npoles=2;
    p.postTIAfiler.type = 'bandpass';
     p.HPF.riseTime=0;
%     p.verbose=1;
    [chA,chB,prprts,mes] = Simulator.runSim(model,p);
    chA = round((max(-ADC_MAX/2,min(chA,ADC_MAX/2))/ADC_MAX+.5)*(2^ADC_NBITS-1))/(2^ADC_NBITS-1);
    measurements=(reshape(chA,[],10+nMes));
    measurements = measurements(:,end-nMes+1:end)';
    snr=mes.osnr_tp1;
    dtheta = Utils.phaseDelayRapp(mean(measurements))-systemOffset;
     r =  mod(-dtheta+2*pi,2*pi)*Utils.dtnsec2rmm(1/p.laser.frequency)/(2*pi);
 
    
end
% nAllowedOutlier = ceil(length(r)*outliersP);
% %
% if(nnz(score<psldThr)>nAllowedOutlier)
%     r=nan;
% else
%     r = r(score>psldThr);
%     score = score(score>psldThr);
% end
% txt=sprintf('mean: %fmm std: %fmm, OSNR: %f[db]\n',mean(r),std(r),mes.osnr_tp1);
% disp(txt);
% % % title(txt);
% % end