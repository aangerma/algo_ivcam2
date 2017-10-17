function [ res ] = writeIVS( filename,ivs)
% Write a .ivs BINARY file. 
% Either a file name <fileName> and a struct <ivStruct> are passed as
% arguments, or a fila naem <fileName> and the arguments: fastCh, slowCh,
% xy, flags are passed as arguments.
% N packets, each packet 128bit: 64fast(b) 16slow(unsigned byte) x(signed word) y(signed word) flags (unsigned word)
if(isstruct(filename) && ischar(ivs))
     res = io.writeIVS( ivs,filename);%inverse input
     return;
end

nPackets = numel(ivs.fast)/64;
if(mod(nPackets,1)~=0)
    error('Number of fast channel samples must be a divition of 64');
end
if(any(size(ivs.xy)~=[2 nPackets]))
     error('xy size should be 2x%d',nPackets);
end
if(any(size(ivs.slow)~=[1 nPackets]))
    error('slow data should be 1x%d',nPackets);
end
if(any(size(ivs.flags)~=[1 nPackets]))
        error('flags data should be 1x%d',nPackets);
end



fastCh64 = typecast(uint8(sum(bsxfun(@times,reshape(uint8(ivs.fast),8,[]),uint8(2.^(0:7)')))),'uint64');
slow_xy_flags = typecast(vec([ivs.slow;reshape(typecast(ivs.xy(:),'uint16'),2,[]);uint16(ivs.flags)]),'uint64')';

fid = fopen(filename, 'wb');
if (fid == -1)  
    error('Cannot open file for writing');
end
fwrite(fid,[fastCh64; slow_xy_flags],'uint64');
res=fclose(fid);
end

