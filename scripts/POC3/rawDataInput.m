%function x=rawDataInput()
%%
fldr = 'd:\data\lidar\EXP\20171126\Record1\';
f = dirFiles(fldr,'*.trc');
v=cellfun(@(x) io.POC.readLeCroyBinaryWaveform(x),f);
dt = v(1).desc.Ts;
v=[v.y];
tia = v(:,1);
pzr1=v(:,2);
pzr2=v(:,4);
pzr3=v(:,3);
clear v;
%%
irdata=tia;
[b,a]=butter_(3,(166e6+[-30 30]*1e6)*2*dt,'bandpass');
irdata=vec(filter(b,a,irdata))';

irdata = abs(irdata);
% [b,a]=fir1(128,30e3*2*dt);
[b,a]=butter_(3,64e6*2*dt);
irdata=vec(filter(b,a,irdata))';

%%
% s=cov([pzr1 pzr3]);
% a=(s(2,2)^2-s(1,2))/(s(1,1)^2+s(2,2)^2-2*s(2,1));
sa = (pzr1+pzr3)/2;
fa = pzr2+0.25*(pzr1-pzr3)/2;
 [b,a]=butter_(3,15e3*dt*2);
 sa = filtfilt(b,a,sa);
% H-sync
% [b,a]=butter_(2,[15e3 25e3]*dt*2,'bandpass');
% fa = filtfilt(b,a,fa);



begind = minind(sa(1e6:floor(length(sa)/2)))+1e6;
endind = maxind(sa(begind:end))+begind;
ivs.slow=vec(irdata(begind:endind))';
ivs.xy=[sa(begind:endind)';fa(begind:endind)'];
%
ivs.slow = mean(buffer_(ivs.slow,4));
ivs.xy = [mean(buffer_(ivs.xy(1,:),4));mean(buffer_(ivs.xy(2,:),4))];
%
% imagesc(Utils.raw2slImg(ivs,3067,512,true))

%
% ivs_=ivs;
% K=0;
% ivs_.xy=[circshift(ivs_.xy(1,:),[0 K]);ivs_.xy(2,:)];
im=fliplr(Utils.raw2img(ivs,3067,[512 512]));
imagesc()