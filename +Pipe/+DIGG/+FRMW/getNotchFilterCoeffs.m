function [baccQ, aaccQ,resedue] = getNotchFilterCoeffs(regs)


maxval = 2;% max of +-2 is the output max/min in the func iirnotch
fpShiftBits = 13;%FIXED : 16-(maxval+1); maxval accupies 3 bits because signed!


%%
%because all sample rates has the same num freq, we are looking at this
%problem like the time per symbol is 1 ns.
baseFreq = 1/double(regs.GNRL.codeLength) ;
Fs = double(regs.GNRL.sampleRate)/64;
%%
frqs=baseFreq.*(1:16);
while(true)
    
frqs(frqs==Fs/2) = [];
upperFrqs = frqs>Fs/2;
if(nnz(upperFrqs)==0)
    break;
end
frqs(upperFrqs)=-frqs(upperFrqs)+Fs;
frqs = abs(frqs);
end
frqs = unique(frqs);
% frqs=unique(round(frqs*1e3))/1e3;
frqs(frqs==0)=[];
%%
bacc = zeros(16,2);
aacc = zeros(16,2);


dw0 = regs.FRMW.notchBw0/(Fs/2)*1e-3;
decayFactor = regs.FRMW.notchBwDecay/(Fs/2);
for i=1:length(frqs)%,regs.FRMW.numNotches)
    
    %get a delta filter
    w0 = frqs(i)/(Fs/2);
    dw = double(dw0*exp(-decayFactor*(i-1)));
    [b,a] = iirnotch_(w0,dw);
    assert(b(1)==b(3));
    assert(a(1)==1);
    aacc(i,:)=a([2 3]);
    bacc(i,:)=b([2 3]);
    
    
end

assert(all(vec([aacc bacc])<=maxval),'not all coefficiants are smaller than 2');

nrm = 2^double(fpShiftBits);
aaccQ = int16(aacc*nrm);
baccQ = int16(bacc*nrm);
resedue = [max(abs(double(aaccQ)/nrm-aacc)) max(abs(double(baccQ)/nrm-bacc))];




end

