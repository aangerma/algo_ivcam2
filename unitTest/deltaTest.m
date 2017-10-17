%   c = Codes.barker13;
nCycles=256;
c = Codes.propCode(128,1);
fs_world = 256;%[GHz]
symbolT = [1 2 4]; %[nsec]
sampleRate = [4 8 16]; %sample rate

figure(4353)
for i=1:3
    
    tx_out = vec(repmat(double(c),1,fs_world*symbolT(i))');
    tx_out = repmat(tx_out,nCycles,1);
    for j=1:3
        
        rxF = (sampleRate(j)/symbolT(i))/64;%[GHz] 64 is CONST rate between fast and slow channels
        nSkip = fs_world/rxF;
        txIn = tx_out(1:nSkip:end);
        
        subplot(3,3,(i-1)*3+j);
        fftplot(txIn);%,rxF);
        %plot(txIn(1:100),'.-');
        xlim auto;
        title(sprintf('symbolT=%.2f,F_{rx}=%d,SR=%d',symbolT(i),rxF,sampleRate(j)))  
        xlabel('normalized freq (Xpi)');
    end
end
subplotTitle(['deltas for code length ' num2str(length(c))])