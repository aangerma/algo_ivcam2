function [ rfZ,rfI,rfC ] = rfGetRaw( obj, N, chunkSz )
%RFGET Return N range finder frames. 
rfZ = zeros(N,1); 
rfI = zeros(N,1); 
rfC = zeros(N,1); 
nSamples = 0;
while nSamples < N 
    flushBuffer(obj,1);
    for i = (nSamples+1):(nSamples+chunkSz)
        if i > N
            break;
        end
      	buff = typecast(obj.read('EXTLrangeFinderBuffer'),'uint16');
        rfZ(i) = buff(1);
        rfC(i) = bitand(buff(2),uint16(15));
        rfI(i) = bitshift(buff(2),4);
    end
    nSamples = nSamples + chunkSz;
end

end

function flushBuffer(obj,delaySec)
    obj.cmd('mwd a00e05e8 a00e05ec 1'); % RegsRangeFlush
    pause(delaySec);
end