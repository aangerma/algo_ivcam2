function ivs = scopePOC1data2ivs(fn,regs)



 memsTableFn  = '\\invcam322\Ohad\data\lidar\memsTables\2014-12-01\60hz\memsTable.mat';
load(memsTableFn,'tblXY');
tblXY;%#ok

%{
    should save the following to file:
    header (fast channel frequncy, clow channel frequncy, etc)
    -mir ticks
    -fast channel (binary, 20gss)
    -slow channel (12bit,125Mhz)
    -all data should be rescaled acording to txTimes (interpolate time for
    txTimes to evenly distributed time(
%}

%% Parse input

if(~exist(fn,'file'))
    error('File "%s" does not exists',fn);
  
end
% %     regs.POCUFn = fullfile(fileparts(scopeBinFilename),'pocConfig.xml');
% %     if(~exist(regs.POCUFn,'file'))
% %         regs.POCU=pocConfigSelector(scopeBinFilename);
% %         struct2xmlWrapper(regs.POCU,regs.POCUFn);
% %     else
% %         regs.POCU = xml2structWrapper(regs.POCUFn);
% %     end

names = fieldnames(regs.POCU);
for i=1:length(names)
    if(isa(regs.POCU.(names{i}),'char'))
        continue;
    end
    regs.POCU.(names{i}) = double(regs.POCU.(names{i}));
end


if(abs(mod(log(double(regs.GNRL.sampleRate))/log(2),1))>1e-3)
    error('sampling rate must be a power of 2');
end

%% Read channels
fprintf('Analog Pipe: importing scope data...');
[t,vref]=io.POC.importScopeDataWpolarity(fn,regs.POCU.refChanIndx);
[~,vsnc]=io.POC.importScopeDataWpolarity(fn,regs.POCU.syncChanIndx);
[~,vslw]=io.POC.importScopeDataWpolarity(fn,regs.POCU.slowChanIndx);
if(regs.POCU.fastChanIndx==regs.POCU.slowChanIndx)
    vfst=vslw;
else
    [~,vfst]=io.POC.importScopeDataWpolarity(fn,regs.POCU.fastChanIndx);
end
fprintf(' Done\n')
fprintf('Analog Pipe: running analog pipe...');

t = t*1e9;
t = t-t(1);
dt = diff(t(1:2));
dt = 1e3/round(1e3/dt);
smplBatch = 1:10000;
refThr = mean(prctile(vref(smplBatch),[1 99]));
txT = round(mean(diff(Utils.getPulseTimes(dt,vref,refThr))));



%% display
figure(11111);
clf;

subplot(4,1,1);
plot(t(smplBatch),vref(smplBatch));ylabel('V_{ref}');xlabel('t[nsec]');
subplot(4,1,2);
plot(t(smplBatch),vsnc(smplBatch));ylabel('V_{sync}');xlabel('t[nsec]');
subplot(4,1,3);
plot(t(smplBatch),vslw(smplBatch));ylabel('V_{slow}');xlabel('t[nsec]');
subplot(4,1,4);
plot(t(smplBatch),vfst(smplBatch));ylabel('V_{fast}');xlabel('t[nsec]');
maximize(gcf);
drawnow;
%% check data
% THR = 0.5;
% vchk = @(v) [max(v)-min(v) (max(v)+min(v))/2];
% vchkA = vchk(vref_(smplBatch));
% assert(abs(vchkA(1)-1)<THR && abs(vchkA(2)-0.5)<THR);
% vchkB = vchk(vsnc_(smplBatch));
% assert(abs(vchkB(1)-1)<THR && abs(vchkB(2)-0.0)<THR);
%% Sync alignment

vsnc_max = max(vsnc);
vsnc_1090 = prctile(vsnc(smplBatch),[10 90]);
if(vsnc_max-vsnc_1090(2)<(vsnc_1090(2)-vsnc_1090(1))/2)
    vsnc(10:20)=vsnc_max*2;
    vsnc_max = vsnc_max*2;
    warning('Sync too low');
end
c = crossing([],conv(vsnc,ones(5,1)/5,'same'),(vsnc_max+vsnc_1090(2))/2);
if(mod(length(c),2)~=0)
    error('Odd number of crossing');
  
end
c = c(1:2);
if(diff(c)*dt>txT)
    error('Edges are too spread');
  
end
i0 = ceil(c(1)+txT/dt);

vslw = vslw(i0:end);
vfst = vfst(i0:end);
vref = vref(i0:end);
vsnc = vsnc(i0:end);
t    = t(i0:end)-t(i0);
%% slow+fast HPF

[bhp,ahp] = butter(3,regs.POCU.hpfCutoffMHZ*1e-3/(.5/dt),'high');
vfst=filter(bhp,ahp,vfst);
vslw=filter(bhp,ahp,vslw);

%% Read reference channel
winSz = round(1/dt)*5;
vref_filtered = conv(vref,ones(winSz,1)/winSz,'same');

if(isempty(vref_filtered))
    error('No distict frequency');
    
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
vslw = interp1(t,vslw,t_aligned,mthd); % abs, lp, ds
vfst = interp1(t,vfst,t_aligned,mthd); % bin
vsnc = interp1(t,vsnc,t_aligned,mthd); % bin

%% verification, should have std close to zero
%{
vrefVrif = interp1(t,vref,t_aligned,mthd);
vrefVrifC = harmonicSignalCleanup(round(2/Tfst),vrefVrif);
vrefRiseVrif=Utils.getPulseTimes(Tfst,vrefVrifC);
displayPeriodicSignalDat(t,vrefVrif,vrefVrifC,vrefRiseVrif);
%}







%% determine mirror ticks(with scope sample jitter)

sncF = (maxind(abs(fft(vsnc(smplBatch)-mean(vsnc(smplBatch)))))/length(smplBatch)/dt);
sncBW = 40e-3;
[b,a]=butter(3,(sncF+[-.5 .5]*sncBW)/(0.5/dt));
vsncC = filter(b,a,vsnc);
vsncC(1:round(1/(dt*sncF)))=nan;


if(isempty(vsncC))
    error('No distict frequency');
  
end

mirTicks = Utils.getPulseTimes(dt,vsncC);
displayPeriodicSignalDat(t,vsnc-mean(vsnc),vsncC,mirTicks);
%     mirTicks/params.dtASIC

[vfst1,vslw1] = io.POC.analogPipe(vfst,vslw,dt,regs);


%===ASIC IR sampler rate adjust to 64 fast samples===
tfst = 1/double(regs.GNRL.sampleRate)*1;%double(regs.GNRL.tx);
tslw = 64/double(regs.GNRL.sampleRate);


%===ASIC IR sampler rate adjust to 64 fast samples===

vslw = interp1((0:length(vslw1)-1)*dt,vslw1,(0:tslw:length(vslw1)*dt-tslw));
vfst = interp1((0:length(vfst1)-1)*dt,vfst1,(0:tfst:length(vfst1)*dt-tfst)); 




vfst = (vfst>0);

%% output data
data = struct();
data.vfst = vfst;
data.vslw = vslw;
data.Tfst = Tfst;
data.Tslw = Tslw;
data.txT = txT;
data.mirTicks = mirTicks;

%%



%     prmsFn = fullfile(baseDir,'pipeParams.xml');
% prmsFn = fullfile(baseDir,'scopeData2imageParams.xml');


%     if(exist(prmsFn,'file'))
%         prms = xml2structWrapper(prmsFn);
%     else
%         error('Reconstruction params file is missing');
%     end

% OUTPUT: constant xy resolution
w = 640*4; %prms.rasterizer.width;
h = 480*4; %prms.rasterizer.height;

fastF = round(1/data.Tfst*1e3)/1e3;

mirTicks = data.mirTicks;
tA = 0:xyT:(length(data.vfst)/fastF)-xyT;

tblXYc = tblXY(1:size(tblXY,1)/2,:);
tblXYc = bsxfun(@times,tblXYc,[w h]*resI./([640 480]*8));
clk = interp1(mirTicks,1:length(mirTicks),tA,'linear','extrap');
tblend = find(clk>size(tblXYc,1),1)-1;

xy=interp1(1:size(tblXYc,1),tblXYc,clk(1:tblend));
xy = int16(round(xy));


qSlow = max(min(data.vslw, 1), 0)*(2^12-1); % crop to [0,1] and scale to fit 12-bit
ivs = struct;



%align # sample to xy
nxy = size(xy,1);
nslow = round(nxy*data.Tslw/xyT);
nfast = nxy*64;


ivs.fast = data.vfst(1:nfast);
ivs.slow = uint16(qSlow(1:nslow));
ivs.xy = xy(1:nxy,:);
ivs.flags=uint8(zeros(1,nxy));


%switch xy
ivs.xy  = ivs.xy (:,[2 1]);
%decrease Y accuracy
ivs.xy(:,2)=bitshift(ivs.xy(:,2),-2);
%transpose
ivs.xy=ivs.xy';


end


function displayPeriodicSignalDat(t,v,vc,pk)
Ndisp=10;
subplot(211)
pkind = pk<pk(Ndisp);
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


% % % function params = pocConfigSelector(fnFull)
% % %     v={};
% % %     nch = 0;
% % %     while(true)
% % %         try
% % %             [t,v{nch+1}]=io.POC.importScopeDataWpolarity(fnFull,nch+1);
% % %         catch
% % %             break;
% % %         end
% % %         nch=nch+1;
% % %     end
% % %     t = t*1e9;
% % %
% % %
% % %
% % %     params.frameTime  = params.frameTime *1e9;
% % %     TX_TIME = input('Bin time(nsec)[1]:');
% % %     if(isempty(TX_TIME))
% % %         TX_TIME = 1;
% % %     end
% % %     TX_SEQ = input('TX sequence[barker]:');
% % %     if(isempty(TX_SEQ))
% % %         TX_SEQ = Codes.barker13();
% % %     end
% % %     params.slowChannelFs = input('slow channel sampling frequency(mhz)[100]')*1e-3;
% % %     if(isempty(params.slowChannelFs))
% % %         params.slowChannelFs=100e-3;
% % %
% % %     end
% % %     params.slowChannelAAFco=params.slowChannelFs/2;
% % %     Ts = diff(t(1:2));
% % %
% % %     n = round(length(TX_SEQ)*TX_TIME/Ts);
% % %     seq = Utils.binarySeq((0:n-1)*Ts,TX_SEQ(:)',TX_TIME);
% % %     c=zeros(nch,n+1);
% % %
% % %     N = 1000;
% % %     for i=1:nch
% % %         viN = v{i}(1:min(floor(length(v{i})/(2*n)),N)*2*n);
% % %         c(i,:)=normByMax(conv(mean(reshape(viN,n*2,[]),2),flipud(seq*2-1),'valid'));
% % %     end
% % %
% % %     figure(334489);
% % %     clf;
% % %     subplot(4,1,1:3)
% % %     dispIndx = 1e5+(1:1000);
% % %     cla;
% % %     hold on
% % %     for i=1:nch
% % %         plot(t(dispIndx),v{i}(dispIndx),'linewidth',3);
% % %     end
% % %     hold off
% % %     legend(num2cell(char((1:nch)+48)));
% % %     set(gca,'color','k')
% % %     subplot(4,1,4)
% % %     cla;
% % %     hold on
% % %     for i=1:nch
% % %         plot(0:n,c(i,:),'linewidth',3)
% % %     end
% % %     hold off
% % %
% % %     set(gca,'color','k')
% % %     title('Correlation');
% % %
% % %     params.refChanIndx=input('Reference: ');
% % %     params.slowChanIndx=input('Signal(IR): ');
% % %     params.fastChanIndx=input('Signal(Depth): ');
% % %     params.syncChanIndx=input('Mirror clock: ');
% % %     params.frameTime =1/60 *1e9;
% % %
% % %
% % %      sc.ref=1;
% % %      sc.ir=2;
% % %      sc.sig=3;
% % %      sc.mir=4;
% % %
% % %
% % %
% % %
% % % end