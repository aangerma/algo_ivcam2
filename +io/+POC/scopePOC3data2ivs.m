function ivs = scopePOC3data2ivs(fn,regs)
TX_FREQ = .5 ;%GHz
%% Parse input

if(~exist(fn,'file'))
    error('File "%s" does not exists',fn);
end

if(abs(mod(log(double(regs.GNRL.sampleRate))/log(2),1))>1e-3)
    error('sampling rate must be a power of 2');
end

%% Read channels

[t,vref]=io.POC.importScopeDataWpolarity(fn,regs.POCU.refChanIndx);
[~,vfst]=io.POC.importScopeDataWpolarity(fn,regs.POCU.fastChanIndx);
[~,vanx]=io.POC.importScopeDataWpolarity(fn,regs.POCU.xaxisChanIndx);
[~,vany]=io.POC.importScopeDataWpolarity(fn,regs.POCU.yaxisChanIndx);
vanx = vanx * double(regs.POCU.xaxisScale);
vany = vany * double(regs.POCU.yaxisScale);
vanx = vanx-mean(vanx);
vany = vany-mean(vany);
t = t*1e9;
t = t-t(1);
dt = diff(t(1:2));
dt = 1e3/round(1e3/dt);

smplBatch = 1:1e6;
refThr = mean(prctile(vref(smplBatch),[1 99]));
txT = round(mean(diff(Utils.getPulseTimes(dt,vref,refThr))));


%handle angles and trim data
 vany=filtfilt(designfilt('lowpassiir','FilterOrder',12,'HalfPowerFrequency',30e3,'SampleRate',1/dt*1e9,'DesignMethod','butter'),double(vany));
 vanx=filtfilt(designfilt('lowpassiir','FilterOrder',12,'HalfPowerFrequency', 1e3,'SampleRate',1/dt*1e9,'DesignMethod','butter'),double(vanx));
%%
% vany = lowPasFilter(vany,dt*1e-9,30e3);
% vanx = lowPasFilter(vanx,dt*1e-9,1e3);

 endi = maxind((vanx(floor(length(vanx)/2):end)))+floor(length(vanx)/2)-1;
 begi = endi - round(1/60*1e9/dt);
 begi = max(begi,1);
 begi = minind(vanx(begi:endi))+begi-1;
 vref=vref(begi:endi);
 vfst=vfst(begi:endi);
 vanx=vanx(begi:endi);
 vany=vany(begi:endi);
 t   =t(begi:endi)-t(begi);

%% display
figure(11111);
clf;

subplot(4,1,1);
plot(t(smplBatch),vref(smplBatch));ylabel('V_{ref}');xlabel('t[nsec]');
subplot(4,1,2);
plot(t(smplBatch),vfst(smplBatch));ylabel('V_{vfst}');xlabel('t[nsec]');
subplot(4,1,3);
plot(t(smplBatch),vanx(smplBatch));ylabel('V_{vanx}');xlabel('t[nsec]');
subplot(4,1,4);
plot(t(smplBatch),vany(smplBatch));ylabel('V_{vany}');xlabel('t[nsec]');
maximize(gcf);
drawnow;

%% Read reference channel
% 
% 
% btot=1;
% atot=1;
% for i=1:4
% [b,a]=iirnotch(1/52*i/(0.5/dt),5e-2/(0.5/dt));
% btot=conv(btot,b);
% atot=conv(atot,a);
% end
% btot = atot-btot;
% vref_filtered=filt_filt(btot,atot,vref);
%%

winSz =round(1/dt)*5;
vref_filtered = conv(vref,ones(winSz,1)/winSz,'same');

if(isempty(vref_filtered))
    errMsg = ('No distict frequency');
    error(errMsg);
    
end
refThr = mean(prctile(vref_filtered(smplBatch),[1 99]));
vrefRise = Utils.getPulseTimes(dt,vref_filtered,refThr);
displayPeriodicSignalDat(t,vref,vref_filtered,vrefRise);

clear vref_filtered
%% time sync
vrefOpt  = (0:length(vrefRise)-1)'*txT;
mthd = 'phchip';
t_aligned = interp1(vrefOpt,vrefRise,t,mthd);

%
vfst = interp1(t,vfst,t_aligned,mthd); %
vanx = interp1(t,vanx,t_aligned,mthd); %
vany = interp1(t,vany,t_aligned,mthd); %
vslw=vfst;
%% verification, should have std close to zero
%{
vrefVrif = interp1(t,vref,t_aligned,mthd);
vrefVrifC = harmonicSignalCleanup(round(2/Tfst),vrefVrif);
vrefRiseVrif=Utils.getPulseTimes(Tfst,vrefVrifC);
displayPeriodicSignalDat(t,vrefVrif,vrefVrifC,vrefRiseVrif);
%}

%% analog pipe
[vfstA,vslwA,tslwA]=io.POC.analogPipe(vfst,vslw,dt,regs);
%%

tfst = 1/(TX_FREQ*double(regs.GNRL.sampleRate));
tslw = 64*tfst;


vslwA = interp1((0:length(vslwA)-1)*tslwA,vslwA,(0:tslw:length(vslwA)*tslwA-tslw),'nearest');


%% Process Fast channel
vfstA = interp1((0:length(vfstA)-1)*dt,vfstA,(0:tfst:length(vfstA)*dt-tfst)); 
vfstA = (vfstA>0);



vanxQ = interp1((0:length(vanx)-1)*dt,vanx,(0:tslw:length(vanx)*dt-tslw));
vanyQ = interp1((0:length(vany)-1)*dt,vany,(0:tslw:length(vany)*dt-tslw));

%%


nxy = floor(length(vfstA)/64);

vanxQ = vanxQ(1:nxy);
vanyQ = vanyQ(1:nxy);
vslwA = vslwA(1:nxy);
vfstA = vfstA(1:nxy*64);
%%
qSlow = max(min(vslwA, 1), 0)*(2^12-1); % crop to [0,1] and scale to fit 12-bit
ivs = struct;
ivs.xy = int16(floor(([vanxQ/regs.POCU.memsOpenX;vanyQ/regs.POCU.memsOpenY])*2*(2^11-1)));
ivs.fast = vfstA;
ivs.slow = uint16(qSlow);




ivs.flags = io.POC.generetePIflags(ivs,regs,TX_FREQ);




end
function vout=lowPasFilter(v,dt,f)
fs=1/dt;
[b,a]=butter(2,f/(0.5*fs));
vout=double(v);
for i=1:6
vout=filt_filt(b,a,vout);
end
end
function displayPeriodicSignalDat(t,v,vc,pk)
Ndisp=10;
subplot(211)
pkind = pk<=pk(Ndisp);
ttind = 1:find(t>pk(Ndisp),1);
refThreshold = interp1(t(ttind),vc(ttind),pk(1));
plot(t(ttind),v(ttind),t(ttind),vc(ttind),t(ttind),t(ttind)*0+refThreshold);
line([pk(pkind) pk(pkind)]',get(gca,'ylim'),'color','m');

pkd=diff(pk);
subplot(212);
hist(pkd,1000);
pk_mean = mean(pkd);
pk_std = std(pkd);
pl = sprintf('\\mu: %g\\etasec \\sigma: %gpsec',pk_mean,pk_std*1e3);
% disp(pl);
title(pl,'interpreter','tex');
drawnow;

end
