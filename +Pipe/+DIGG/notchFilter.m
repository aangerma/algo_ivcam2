function slowOut=notchFilter(slow,regs)

slowOut = slow(:)';

if(regs.DIGG.notchBypass)
    return;
end
%% NOTCH FILTER
fpShiftBits = 13; %CONSTANT, derived from #bits of coefficient and maximum fp value of coefficient

for i=1:16 %max num of regs
    
    ain = typecast(regs.DIGG.notchA(i),'int16');
    bin = typecast(regs.DIGG.notchB(i),'int16');
    
    if(all([ ain bin]==0))
        bb = int16([bitshift(1,fpShiftBits) 0 0]);
        aa = int16([bitshift(1,fpShiftBits) 0 0]);
    else
        aa = [bitshift(1,fpShiftBits) ain]';
        bb = [bin(2) bin]';
    end
    slowOut = Pipe.DIGG.filter16b(bb,aa,slowOut,uint8(fpShiftBits));
end

if(regs.MTLB.debug)
    %%
    ff=figure(523121);clf
    set(ff,'Name','DIGG notch');
    bb=1;aa=1;
    for i=1:16
        b=double(typecast(regs.DIGG.notchB(i),'int16'))/2^fpShiftBits;
        a=double(typecast(regs.DIGG.notchA(i),'int16'))/2^fpShiftBits;
        if(all([a b]==0))
            a=[1 0 0];b=[1 0 0];
        else
            a=[1 a];b=b([2 1 2]);
        end

        bb=conv(bb,b);
        aa=conv(aa,a);
    end
    
    fs = double(regs.GNRL.sampleRate)/64;
    [H,f]=freqz_(bb,aa,2^16);
    a(1) = subplot(311);
    semilogy(f/pi*fs*.5,abs(H));axis tight
    xlabel('F[Ghz]');
    ylabel('||');
    
    title('Filter design');
    a(2) = subplot(312);
    fftplot(slow,fs);axis tight
    title('Input')
    a(3) = subplot(313);
    fftplot(slowOut,fs);axis tight
    title('Output')
    
    linkaxes(a,'x')

end

slowOut=slowOut(:)';
end