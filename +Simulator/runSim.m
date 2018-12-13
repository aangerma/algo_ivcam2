function [chA_v,chB_vQ,prprts,measurments] = runSim(model, prms, filename )
    %UNITS:
    % freq: Ghz
    % time: nSec
    % distance: mm
    txQuietHeadTime=0;
    
    Tx = 1/prms.laser.frequency;
    Tc = Tx/prms.overSamplingRate; %over sample time
    Ts = 1/prms.Comparator.frequency;
    
    %convert sample offset from [0-2pi] to offset in fractions of the sampling
    %rate Ts. Make sure that is is units of Tc, the oversampling rate.
    
    
    %concatenate transimtted signal and quiet tail time
    
    %create oversample time domain
%     t_c = ((prms.t0-Tx):Tc:(prms.t0+prms.runTime+Tx))';
    t_c = ((prms.t0):Tc:(prms.t0+prms.runTime-Tc))';
    
    
    
    if(isnumeric(prms.laser.peakCurrent))
        laserPeakcurrent = prms.laser.peakCurrent;
    else
        laserPeakcurrent = prms.laser.peakCurrent(t_c);
    end
    laserHi = (laserPeakcurrent-prms.laser.thresholdCurrent)*prms.laser.slopeEfficiency;
    laserLo = (prms.laser.biasCurrent-prms.laser.thresholdCurrent)*prms.laser.slopeEfficiency;
    
    transmitedSignalJitter = Simulator.aux.randnWithS2Sbound(round(prms.runTime/Tx),prms.laser.jitterRMS,prms.laser.jitterMaxC2C);
    transmitedSignalJitter = interp1(linspace(0,1,round(prms.runTime/Tx)),transmitedSignalJitter,linspace(0,1,length(t_c)))';
    %transmitted signal with recieved signal strength
    if isa(prms.laser.txSequence, 'function_handle')
        txSeqLength = Tx;
        y_c = prms.laser.txSequence(t_c).*laserHi+laserLo;
    else
        txSeqLength = length( prms.laser.txSequence)*Tx;
        y_c = cyclicBinarySeq(t_c+transmitedSignalJitter-txQuietHeadTime, prms.laser.txSequence,Tx).*laserHi+laserLo;%[mW]
    end
    y_c = applyNoisyLPF(Tc,y_c,0.35/prms.laserDriver.riseTime,1,0);%[mW]
    
    fParasitic = 1/(2*pi*prms.laserDriver.parasiticResistance*prms.laserDriver.parasiticCapacitance*1e-12)*1e-9;
    y_c = applyNoisyLPF(Tc,y_c,fParasitic,1,0);%[mW]
    
    y_c = applyNoisyLPF(Tc,y_c,0.35/prms.laser.riseTime,1,0);%[mW]
    
    measurments.opticalOutputPowerDCRMS = sqrt(mean(y_c.^2));
    measurments.opticalOutputPowerP2P = diff(prctile_(y_c,[10 90]));
    %{
   +-------+      +-------+
   |  TX   |  --> |  ENV  |
   +-------+      +-------+
    %}
    specularityFactor=1;
    dist = interp1(model.t,model.r,t_c,'linear','extrap');
    albedoEff = interp1(model.t,model.a,t_c,'linear','extrap')*prms.environment.wavelengthReflectivityFactor;
    
    %delta for each time slot (for the loaded model)
    tau_delay = Utils.rmm2dtnsec(dist); %nsec
    y_c = y_c*prms.optics.lensArea ./((1+dist).^2 * specularityFactor*pi ).*albedoEff*prms.optics.TXopticsGain; % mW
%     y_c = Simulator.aux.relocateTimeFrame(t_c,y_c,t_c+tau_delay);%[mW]
    y_c = Utils.timePropogate(y_c,tau_delay/Tc);
    o_c = y_c;%[mW]
    
    
    %TODO RXopticsGain is angle dependant
    y_c = y_c * prms.optics.RXopticsGain;
    o_c = o_c * prms.optics.RXopticsGain;
    
    
    
    measurments.opticalInputPowerDCRMS = sqrt(mean(y_c.^2));
    measurments.opticalInputPowerP2P = diff(prctile_(y_c,[10 90]));
    %{
   +-------+      +-------+
   |  ENV  |  --> |  APD  |
   +-------+      +-------+
    %}
    
    
    
    
    apdResponsivity = prms.APD.responsivity * prms.APD.mFactor;
    y_c = min(y_c,prms.APD.overloadPower)*apdResponsivity;%[mA]
    o_c = min(o_c,prms.APD.overloadPower)*apdResponsivity;%[mA]
    
    y_c = y_c+prms.APD.darkCurrentDC*1e-9*1e3;%[mA]
    
    % ambientMS = prms.environment.ambientNoise*prms.optics.opticalFilterBandWidth*1e-6*sqrt(prms.optics.RXopticsGain); %mW/sqrt(Hz)
    ambientMS = prms.environment.ambientNoiseFactor*1e-6*sqrt(prms.optics.RXopticsGain)/sqrt(1e9); %mW/sqrt(Hz)
    
    apdCutoffFreq = 0.35/prms.APD.riseTime;
    apdNEP = sqrt(2*1.6e-19*prms.APD.excessNoiseFactor*prms.APD.darkCurrentAC*1e-9)/apdResponsivity*1e3; %mW/sqrt(Hz)
    
    apdSHOT = sqrt(2*1.6e-19*prms.APD.excessNoiseFactor*y_c*1e-3)/apdResponsivity*1e3; %mW/sqrt(Hz)
    
    aptNEPtot = sqrt(apdNEP^2 + apdSHOT.^2 + ambientMS^2)*apdResponsivity;
    
    o_c = applyNoisyLPF(Tc,o_c,apdCutoffFreq,1,0     );%[mA]
    y_c = applyNoisyLPF(Tc,y_c,apdCutoffFreq,1,aptNEPtot);%[mA]
    
    measurments.apdNEP  = apdNEP*sqrt(apdCutoffFreq*1e9);
    measurments.apdOutputCurrentDCRMS = sqrt(mean(y_c.^2));
    measurments.apdOutputCurrentACRMS = std(y_c);
    measurments.apdOutputCurrentP2P = diff(prctile_(y_c,[10 90]));
    
    
    %{
   +-------+      +-------+
   |  APD  |  --> |  TIA  |
   +-------+      +-------+
    %}
    
    tiaPreAmpIRN = prms.TIA.preAmpIRN;
    tiaPreAmpCutoffFreq = 0.35/prms.TIA.preAmpRiseTime;
    preAmpGain = prms.TIA.preAmpGain;
    %  preAmpGain = 1;
    o_c = applyNoisyLPF(Tc,o_c,tiaPreAmpCutoffFreq,4,0     )*preAmpGain; %[mV]
    y_c = applyNoisyLPF(Tc,y_c,tiaPreAmpCutoffFreq,4,tiaPreAmpIRN)*preAmpGain; %[mV]
    
    % g1 = 60/7*4e3;
    % g2 = 60/7*2e3;
    % g3 = 60/7*1e3;
    % xl = 2e-3;
    % xb = 5e-3;
    % xfs= 40e-3;
    %
    % m = @(v,v1,v2) double(v>v1 & v<v2);
    % compander = @(yin) m(yin,0,xl).*((g1+g2+g3)*yin)+m(yin,xl,xb).*(g1*xl+(g2+g3)*yin)+m(yin,xb,xfs).*(g1*xl+g2*xb+g3*yin)+m(yin,xfs,inf)*(g1*xl+g2*xb+g3*xfs);
    % prms.TIA.postAmpGain = 1;
    % y_c = compander(y_c);
    % o_c = compander(o_c);
    
    offsetVoltage = prms.TIA.inputBiasCurrent*prms.TIA.preAmpGain;
    
    o_c = (o_c+offsetVoltage)*prms.TIA.postAmpGain;
    y_c = (y_c+offsetVoltage)*prms.TIA.postAmpGain;
    
    o_c = min(o_c,prms.TIA.overloadVoltage); %[mV]
    y_c = min(y_c,prms.TIA.overloadVoltage); %[mV]
    
    measurments.tiaPreAmpIRN  = tiaPreAmpIRN*sqrt(tiaPreAmpCutoffFreq*1e9);
    measurments.tiaOutputVoltageDCRMS = sqrt(mean(y_c.^2));
    measurments.tiaOutputVoltageACRMS = std(y_c);
    measurments.tiaOutputVoltageP2P = diff(prctile_(y_c,[10 90]));
    
    %{
   +-------+      +-------+
   |  TIA  |  --> |   HPF |
   +-------+      +-------+
    %}
    if(prms.HPF.riseTime>0)
        hpfCuroff = 0.35/prms.HPF.riseTime;
        [b,a]=butter_(1,hpfCuroff*Tc*2,'high');
        y_c = filter(b,a,y_c);
        o_c = filter(b,a,o_c);
    elseif(prms.HPF.riseTime==0)
        y_c = y_c-mean(y_c);
        o_c = o_c-mean(o_c);
    end
    
    if(isfield(prms,'postTIAfiler') && all(prms.postTIAfiler.freq<0))
        wn = prms.postTIAfiler.freq*Tc*2;
        np =prms.postTIAfiler.npoles;
        t = prms.postTIAfiler.type;
        [b,a]=butter_(np,wn,t);
        y_c = filter(b,a,y_c);
        o_c = filter(b,a,o_c);
    end
    
    
    measurments.hpfOutputVoltageDCRMS = sqrt(mean(y_c.^2));
    measurments.hpfOutputVoltageACRMS = std(y_c);
    measurments.hpfOutputVoltageP2P = diff(prctile_(y_c,[10 90]));
    
    
    measurments.hpfPureSignalOutputVoltageDCRMS = sqrt(mean(o_c.^2));
    measurments.hpfPureSignalOutputVoltageACRMS = std(o_c);
    measurments.hpfPureSignalOutputVoltageP2P = diff(prctile_(o_c,[10 90]));
    
  
    
    %{
 CHANNEL A/DEPTH:
   +-------+      +-------+
   |  HPF  |  --> |SAMPLER|
   +-------+      +-------+
    %}
    
    %OSNR calculation
    ind0=find(t_c>tau_delay(1)+txQuietHeadTime+1,1);
    vSg = std(o_c(ind0:end));
    vNs = std(y_c(ind0:end)-o_c(ind0:end));
    measurments.osnr_tp1 = 10*log10(vSg/vNs);
    
    %buit the sampling kernel. % add 0.5Ts edge at each side for tail effects
    tkerBase_t = (-Ts/2:Tc:1.5*Ts)';
    % kerFunc = (tkerBase_t>=0 & tkerBase_t<Ts)*Tc/Ts;    %ideal sampler
    kerFunc  = (tkerBase_t>=0 & tkerBase_t<=Tc);           %delta
    % kerFunc = exp(-1e7*(tkerBase_t-Ts/2).^8)*Tc/Ts;     %gaussian
    
    
    
    nSamples = prms.runTime/Ts;
    sampleTimes =prms.t0 + (0:nSamples-1)'*Ts;
    
    sampleNoise = Simulator.aux.randnWithS2Sbound(length(sampleTimes),prms.Comparator.jitterRMS,prms.Comparator.jitterMaxC2C);
    sampleTimes = sampleTimes+sampleNoise;
    
    
    
    
    %auxilarity function to convert between time and indices
    tc2indx = @(t) round((t-t_c(1))/Tc+1);
    
    
    
    
    
    
    %create a matrix that each row is the time slot that the sample will sample
    %each row is the entire sample and it's length is equal to the kernel
    %length
    
    
    
    indices=bsxfun(@plus,tkerBase_t',sampleTimes);
    
    %find the indices of the time slots
    indices=tc2indx(indices);
    
    indices(indices<1)=1;
    indices(indices>length(y_c))=length(y_c);
    
    if(strcmpi(prms.measurmentStageType,'lim'))
        
        %1.binarize
        %assuming +vvc=1 and -vcc=0
        
        y3_c = applyNoisyLPF(Tc,y_c,0.35/prms.Comparator.riseTime,prms.Comparator.filterOrder,prms.Comparator.irn);
        overSensitivityThrIndx = abs(y3_c)>prms.Comparator.sensitivity/2;
        yQ_c = nan(size(y3_c));
        yQ_c(overSensitivityThrIndx)=double(y3_c(overSensitivityThrIndx)>0);
        %memory system
        yQ_c(1)=0;
        yQ_cnan = isnan(yQ_c);
        
        
        iii=1;
        while(true)
            ind0 = find(yQ_cnan(iii:end),1);
            if(isempty(ind0))
                break;
            end
            ind0 = ind0+iii-1;
            ind1 = find(~yQ_cnan(ind0:end),1)+ind0-2;
            yQ_c(ind0:ind1)=yQ_c(ind0-1);
            iii=ind1+1;
        end
        %      yQ_c(~overSensitivityThrIndx)=double(randn(nnz(~overSensitivityThrIndx),1)>0);
        %2. S/H
        %multiply these samples with the kernel samples
        chA_v = yQ_c(indices)*kerFunc;
        chA_v = (chA_v>.5);
        %     yScope_s = chA_v;
    elseif(strcmpi(prms.measurmentStageType,'scope'))
        %1. S/H
        %multiply these samples with the kernel samples
%         kerFunc = (tkerBase_t>=0 & tkerBase_t<Ts)*Tc/Ts;
        chA_v = y_c(indices)*kerFunc;
        %      yScope_s = chA_v;
    elseif(strcmpi(prms.measurmentStageType,'analog'))
        chA_v=y_c;
    else
        error('unknown measurment stage');
    end
    
    
    
    
    %{
 CHANNEL B/IR:
   +-------+      +-------+    +-------+   +-------+
   |  HPF  |  --> |  ABS  |--> |  LPF  |-->|SAMPLER|
   +-------+      +-------+    +-------+   +-------+
    %}
    yA_c = abs(y_c);
    
    slowT = 1/prms.HDRsampler.frequency;
    nSamplesd=round(slowT/Tc);
    if(prms.HDRsampler.riseTime>0)
        irLPFcutoff = 0.35/prms.HDRsampler.riseTime;
        [filb,fila] = butter_(prms.HDRsampler.filterOrder,Tc*2*irLPFcutoff,'low');
        yA_c = filter(filb,fila,yA_c);
    end
    smplInd = floor(nSamplesd/2+1:nSamplesd:length(t_c));
    chB_t = t_c(smplInd);
    chB_v = conv(yA_c,ones(1,nSamplesd)/nSamplesd,'same');
    chB_v = chB_v(smplInd);
    chB_vQ = max(min(chB_v,prms.HDRsampler.maxVal),prms.HDRsampler.minVal)/(prms.HDRsampler.maxVal-prms.HDRsampler.minVal);
    chB_vQ = uint16(round(chB_vQ*2^(prms.HDRsampler.nBits-1)));
    
    
    %calculate the laser start times
    txTimes = txQuietHeadTime+ txSeqLength*(0:floor(prms.runTime/txSeqLength))+prms.t0;
    txTimes(txTimes<t_c(1))=[];
    % txTimes(txTimes'>prms.runTime-txSeqLength-tau_delay(tc2indx(txTimes))+prms.t0)=[];
    
    
    if(prms.verbose)
        cla
        figure;
        chA_t = prms.t0+Ts*(0:nSamples-1)'; %%+Ts/2 ;
        
        yl =[min(y_c) max(y_c)];
        for lastGood=1:length(txTimes)
            sSlim = txTimes(lastGood) + [0 length(prms.laser.txSequence)*Tx];
            sSlim = min(t_c(end),sSlim);
            sSlim = sSlim+tau_delay(tc2indx(sSlim))';
            sSlim = min(t_c(end),sSlim);
            patch(sSlim([1 1 2 2]),yl([1 2 2 1]),'w','edgecolor','g','linewidth',3)
        end
        hold on
         if(strcmpi(prms.measurmentStageType,'lim'))
        bar(chA_t,chA_v*max(y_c),.5,'c','edgecolor','none');
        plot(chB_t,chB_v);
         elseif(strcmpi(prms.measurmentStageType,'scope'))
             stem(chA_t,chA_v);
         end
        %     plot(t_c,y2_c,'k');
        
        plot(t_c,y_c,'r');%%,t_c,o_c,'r'
        
        
        hold off
        axis tight
        title(sprintf('OSNR[db]=%f',measurments.osnr_tp1));
    end
    prprts = struct('fastF',prms.Comparator.frequency,'slowT',slowT,'templateT',length(prms.laser.txSequence),'xyT',txSeqLength);
    
    % if you want the IVLpi file to be created
    if (exist('filename','var'))
        
        % xy - vector time between pulses
        pulse_time = model.t(1):txSeqLength:model.t(2);
        
        
        xy = [   pulse_time' zeros(length(pulse_time),1)   ];
        
        
        
        
        
        
        io.writeIVLpi( filename,chA_v, chB_vQ, xy, prprts );
        
    end
    
    
end %func

function yout = applyNoisyLPF(Tc,yin,cutOffFreq,filterOrder,stdNoiseHz)
    
    if(cutOffFreq<=0 || isinf(cutOffFreq))
        yout=yin;
        return;
    end
    noiseStd = stdNoiseHz * sqrt(cutOffFreq*1e9);
    % noiseStd = stdNoiseHz * sqrt(2*cutOffFreq*1e9);%?????????????SHOULD BE 2*cutOffFreq????
    
    %colorize white noise, then set STD
    rrr = randn(size(yin));
    n = Simulator.aux.applyLPF(Tc,rrr,cutOffFreq,filterOrder);
    n = n/std(n).*noiseStd;
    yout = Simulator.aux.applyLPF(Tc,yin,cutOffFreq,filterOrder);
    yout = yout + n;
    
end %func


function y = cyclicBinarySeq(t,b,T)
    tmax = max(t);
    seqLen = length(b)*T;
    n = ceil(tmax/seqLen);
    b=repmat(b(:),n,1)';
    y = Simulator.aux.binarySeq(t,b,T);
    y=y(:);
end %func