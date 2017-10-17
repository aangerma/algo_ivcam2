clear;
%
inputRange = 4200;


p = xml2structWrapper('\\invcam322\ohad\data\lidar\simulatorParams\params_860SKU1_indoor.xml');
p.laser.txSequence = Codes.propCode(32,1);
% 
p.laser.frequency = 1;
p.Comparator.frequency = 16;
p.HDRsampler.frequency=0.25;

% p.laser.frequency = 1;
% p.Comparator.frequency = 16;


% p.TIA.overloadVoltage=inf;
% p.APD.overloadPower=inf;
%           p.laser.txSequence = Codes.propCode(106,1);
%            p.laser.txSequence = Codes.propCode(128,1);
% p.laser.txSequence = Codes.golay26;
nav = 9;
nMes = 1;


p.verbose=1;



p.runTime= (length(p.laser.txSequence)/p.laser.frequency)*(1+(nMes+1)*nav);



% p.environment.ambientNoiseFactor=4.5;%outdoor 2500lux

model =struct('t',[0 p.runTime],'r',[ inputRange  inputRange],'a',[ 1  1 ]);

% model =struct('t',[0 p.runTime*1/3-1e-3 p.runTime*1/3 p.runTime*2/3 p.runTime*2/3+1e-3 p.runTime*3/3],'r',[ inputRange inputRange inputRange+300 inputRange+300  inputRange inputRange],'a',[1 1 1 1 1  1 ]);

GT = false;
if(GT)
    
    p.APD.darkCurrentAC=0;
    p.APD.darkCurrentDC=0;
    p.APD.excessNoiseFactor=0;
    p.Comparator.irn=0;
    p.Comparator.jitterMaxC2C=0;
    p.Comparator.jitterRMS=0;
    p.Comparator.sensitivity=0;
    p.environment.ambientNoise=0;
    p.environment.ambientNoiseFactor=0;
    p.TIA.inputBiasCurrent=0;
    p.TIA.preAmpIRN=0;
end




%
rng(1);
[chA,chB,prprts,mes] = Simulator.runSim(model,p);
% disp(mes);
%
% subplot(212);
%%
% verbose=2;
% frw = Firmware();
% clear regs
% regs.FRMW.txCode = false(1,128);
% regs.FRMW.txCode(1:length(p.laser.txSequence)) = p.laser.txSequence;
% regs.GNRL.codeLength = uint8(length(p.laser.txSequence));
% regs.RAST.biltBypass=1;
% regs.GNRL.sampleRate = uint8(p.Comparator.frequency/p.laser.frequency);
% frw.setRegs(regs,'struct');
% 
% 
% 
% stats = Utils.sequenceDetector(chA,frw,nav,verbose);%%%%%% stats = Utils.sequenceDetector(chA,chB,frw,nav,verbose);
% 
% 
% txt=sprintf('mean: %fmm std: %fmm, OSNR: %f[db] (gt=%d)\n',stats.mean,stats.std,mes.osnr_tp1,inputRange);
% fprintf('%s\n',txt);
% %  title(txt);
% %  fprintf('%f %f\n',inputRange,mean(r));
