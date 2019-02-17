function fns=writeLUTbin(obj,d,fn,oneBaseCount)
    if ~exist('oneBaseCount','var')
        oneBaseCount = false;
    end
    PL_SZ=4072*8/32;
    
    n = ceil(size(d,1)/PL_SZ);
    fns=cell(n,1);
    for i=0:n-1
        fns{i+1}=sprintf(strrep(fn,'\','\\'),i+oneBaseCount*1);
        fid = fopen(fns{i+1},'w');
        ibeg = i*PL_SZ+1;
        iend = min((i+1)*PL_SZ,size(d,1));
        fwrite(fid,getLUTdata(d(ibeg:iend,:)),'uint8');
        fclose(fid);
    end
    
    
    
end

function s=getLUTdata(addrdata)
    
    %ALL SHOULD BE LITTLE ENDIAN
    data = [addrdata{:,2}];
    addr = uint32(addrdata{1,1});
    
    touint8 = @(x,n)  vec((reshape(typecast(x,'uint8'),n,[])))';
    
    s=[uint8(133) uint8(7) touint8(uint32(addr),4) touint8(uint16(length(data)),2) touint8(data,4)];
end
