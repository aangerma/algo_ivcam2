function vout = applyAsicFilter(vin,fs,fn,optVect)

p  =xml2structWrapper(fn);
vout = vin;

%% BPF
filDataBPF = p.BPfilter.(optVect.BPfilter);
[bBPF,aBPF] = filCoefs(filDataBPF,fs);
%      figure;[h,f]=freqz(bBPF,aBPF,2^16,10);loglog(f,abs(h));grid on;
vout = filter(bBPF,aBPF,vout);

hNoise = p.BPnoise.(optVect.BPnoise);
vout = addFilterNoise(bBPF,aBPF,hNoise,vout,fs);



%% ABS
filDataABS = p.abs.(optVect.abs);
vout = interp1(filDataABS.vin,filDataABS.vout,abs(vout),'linear','extrap');




%% lpf- AA amplifier
filDataLPF = p.LPfilter.(optVect.LPfilter);
%     vout = sigFilt(vout,fs,f,v);
[bLPF,aLPF] = filCoefs(filDataLPF,fs);
vout = filter(bLPF,aLPF,vout);
%     figure;[h,f]=freqz(bLPF,aLPF,2^16,10);loglog(f,abs(h));grid on;

hNoise = p.LPnoise.(optVect.LPnoise);
vout = addFilterNoise(bLPF,aLPF,hNoise,vout,fs);



end


function vout = addFilterNoise(b,a,hNoise,vin,fs)
bd = hNoise.f>fs/2;
hNoise.n=hNoise.n(~bd);
hNoise.f=hNoise.f(~bd);

[H,~]=freq_z(b,a,hNoise.f);

na = hNoise.n.*abs(H);

noiseStd = sqrt(sum(na(1:end-1).^2.*diff(hNoise.f*1e9)));


n = randn(size(vin));
n = filter(b,a,n);
n = n/std(n)*noiseStd;
vout = vin*hNoise.gain+n;
end


function [b,a] = filCoefs(filData,fs)

b=1;
a=1;
for i=1:length(filData.p)
    [bi,ai] = fil1p(filData.p(i)*2/fs);
    a = conv(a,ai);
    b = conv(b,bi);
end

for i=1:length(filData.z)
    [bi,ai] = fil1z(filData.z(i)*2/fs);
    a = conv(a,ai);
    b = conv(b,bi);
end

while(a(1)==0 && b(1)==0)
    a(1)=[];
    b(1)=[];
end

end