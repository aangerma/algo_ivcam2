function vc=harmonicSignalCleanup(dt,v)
N_HARMONICS = 1;
FFT_NSAMPLES_EVAL = 1e8;
N_POLES = 1;
fs = 1/dt;
nFreqs = 1e6;

v_FFT = abs(fft(v(1:min(FFT_NSAMPLES_EVAL,length(v)))-mean(v), nFreqs));
[v1,m1]=max(v_FFT(1:floor(length(v_FFT)/2)));
% v2=max(v_FFT(2*m1:floor(length(v_FFT)/2)));
% if(v2/v1>0.8)
%     vc=[];
%     return;
% end
refThreshold = ((-prctile(-v(1:2*m1),5))+prctile(v(1:2*m1),5))/2;


freqMax=interp1(1:nFreqs,linspace(0,fs,nFreqs),m1);
cutoffFreq = freqMax*N_HARMONICS;
[b,a]=butter(N_POLES,cutoffFreq/(0.5*fs),'low');
vc = filter(b,a,v);

vc(1:find(v<refThreshold,1,'first')+1)=nan;


% v_FFT = fft(v-mean(v));
% [~,m]=max(abs(v_FFT(1:floor(length(v_FFT)/2))));
% signalTimes = round(length(v)/(m-1));
% smoothWinSize = signalTimes/32;
% vc = conv(v,fspecial('gaussian',[1 signalTimes],smoothWinSize),'same');
% vc(1:signalTimes)=nan;
% vc(end-signalTimes+1:end)=nan;
end
