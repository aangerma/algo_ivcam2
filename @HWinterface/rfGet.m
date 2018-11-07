function [ rfZ,rfI,rfC ] = rfGet( obj, N, raw)
%RFGET Return N range finder frames. Either raw, or filtered bad samples are removed).
nSamples = 0;
while nSamples < N 
    flushBuffer(obj,1)
%     if ~strcmp(a(end-7:end),'00000000')
        for i = 1:5000
           buff = hw.read('EXTLrangeFinderBuffer')
           v = v(end-7:end);
           Z(i) = hex2dec(v(end-3:end));
           C(i) = hex2dec(v(end-4:end-4));
           I(i) = hex2dec(v(end-6:end-5));
        end
        tabplot;
        plot(Z);
        tabplot;
        plot(C);
        tabplot;
        plot(I);

    else
        fprintf('all zero');
    end 
    
end

end

function flushBuffer(obj,delaySec)
    hw.cmd('mwd a00e05e8 a00e05ec 1'); % RegsRangeFlush
    pause(delaySec);
end