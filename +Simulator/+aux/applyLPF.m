function yout = applyLPF(Tc,yin,cutOffFreq,N)
if(isempty(cutOffFreq))
    yout = yin;
    return;
end
%%

cutOffFreqN=cutOffFreq*Tc*2;
%
 [b,a]=butter_(N,cutOffFreqN,'low');

%   b = fir1(10,fvn); a=1;

yout = filter(b,a,yin);

if(0) 
    %%
%     subplot(2,1,1)
    [H,f]=freqz(b,a,2^16,1/Tc);
    loglog(f,abs(H))
    grid on
    xlabel('Frequency (Hz) ')
    ylabel('Magnitude Response')
%     subplot(2,1,2)
%     zplane(b,a)
%     plot(1:length(yin),yin,1:length(yin),yout)
end

end