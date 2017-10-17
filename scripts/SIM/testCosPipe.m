p = xml2structWrapper('\\invcam322\ohad\data\lidar\simulatorParams\params_860SKU1_indoor.xml');

% p.laserDriver.riseTime = 0;
% p.APD.overloadPower=inf;
% p.laser.riseTime = 0;
% p.laser.jitterRMS = 0;
% p.laser.jitterMaxC2C = 0;
% p.APD.riseTime = 0;
% p.APD.darkCurrentAC = 0;
% p.APD.darkCurrentDC = 0;
% p.APD.excessNoiseFactor=0;
% p.TIA.preAmpRiseTime = 0;
% p.laserDriver.parasiticResistance=0;
% p.TIA.preAmpIRN = 0 ;
% p.TIA.overloadVoltage = inf;
%  p.environment.ambientNoiseFactor=0;
p.overSamplingRate=1000;

p.laser.frequency = 0.2;
p.Comparator.frequency = 3*p.laser.frequency ;
abmbiguityRange = Utils.dtnsec2rmm(1/p.laser.frequency);
p.HPF.riseTime=0;


clear r
ndists = 20;
distances = linspace(0,2500,ndists);
rng(1);
[~,systemOffset] = testLIDARsim_cos(distances(1),p,0);%calib

ntrials = 40;
r = zeros(length(distances),ntrials);
snr = zeros(length(distances),1);
for i=1:ntrials
    rr = zeros(length(distances),1);
    sss = cell(length(distances),1);
    parfor kidx = 1:length(distances)
        rng(i);
        [rr(kidx),~,snr_] = testLIDARsim_cos(distances(kidx),p,systemOffset);
       
    end
    if ~mod(i,10)
        fprintf('.');
    end
    
    r(:,i)=rr;
end
fprintf(1,'\n');
%%
% figure(1); clf;
hold on;
%  r_=r;
r_=r/(Utils.dtnsec2rmm(1/p.laser.frequency)/(2*pi));
r_ = unwrap(r_-pi)-pi;

r_(:,r_(1,:)<-pi/2)=r_(:,r_(1,:)<-pi/2)+2*pi;

 r_ = r_*Utils.dtnsec2rmm(1/p.laser.frequency)/(2*pi);


err = bsxfun(@minus,r_,distances');

% subplot(121);
% plot(distances,err,'.-');
% subplot(122);

plot(distances,std(err,[],2));
grid on

rto = std(err,[],2)'./distances;
accThr = 0.02;
dbreak = distances(find(~isinf(rto) & rto>accThr,1));
abreak = dbreak*accThr;
% line([dbreak dbreak;get(gca,'xlim')]',[get(gca,'ylim');abreak abreak]','linestyle','--','color','r');
fprintf('Last distance with %d%% accuracy: %d\n',round(accThr*100),round(dbreak));