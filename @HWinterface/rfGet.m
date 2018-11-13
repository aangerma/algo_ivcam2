function [ rfZ,rfI,rfC ] = rfGet( obj, N )
%RFGET Return N range finder frames. 
rfZ = zeros(N,1); 
rfI = zeros(N,1); 
rfC = zeros(N,1); 
for i = 1:N 
    if mod(i-1,8000) == 0
        flushBuffer(obj,1);
    end
    
    buff = typecast(obj.read('EXTLrangeFinderBuffer'),'uint16');
    rfZ(i) = buff(1);
    rfC(i) = bitand(buff(2),uint16(15));
    rfI(i) = bitshift(buff(2),-4);
end

end

function flushBuffer(obj,delaySec)
    obj.cmd('mwd a00e05e8 a00e05ec 1'); % RegsRangeFlush
    pause(delaySec);
end