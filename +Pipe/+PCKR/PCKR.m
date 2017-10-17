function [stream1, stream2, stream3] = PCKR(pflow,regs,luts,traceOutDir)


% if(~regs.PCKR.selFg)
if(regs.PCKR.privacyEn)
    zIn = ones(size(pflow.zImg),'uint16')*regs.PCKR.privacyZ;
    cIn = ones(size(pflow.cImg),'uint8' )*regs.PCKR.privacyC;
    iIn = ones(size(pflow.iImg),'uint8' )*regs.PCKR.privacyI;
else
    zIn = pflow.zImg;
    cIn = pflow.cImg;
    iIn = pflow.iImg;
end

zstream = [zIn(:)' zeros(1,regs.PCKR.padding,'uint16')];
cstream = [cIn(:)' zeros(1,regs.PCKR.padding,'uint8')];
istream = [iIn(:)' zeros(1,regs.PCKR.padding,'uint8')];




if(regs.PCKR.allInDepth)
    
    if(regs.GNRL.rangeFinder)
        zstream=[zstream 0];
        istream=[istream 0];
        cstream=[cstream 0];
    end
    %|Cn+1 1'h |1'h0 | In+1 2'h| Zn+1 4'h| Cn 1'h |1'h0 | In 2'h| Zn 4'h|
    stream1 = typecast(vec([...
        reshape(typecast(zstream(1:2:end),'uint8'),2,[])'...
        istream(1:2:end)'...
        2^4.*cstream(1:2:end)'...
        reshape(typecast(zstream(2:2:end),'uint8'),2,[])'...
        istream(2:2:end)'...
        2^4.*cstream(2:2:end)'...
        ]'),'uint64');
    
    stream2 = [];
    stream3 = [];
else
    
    if(regs.PCKR.depthEn)
        % | Dn+3 4'h|...|Dn+0 4'h|
        stream1 =   buffer_(zstream(:),4)';
        stream1 = sum(uint64(stream1).*repmat(uint64(2.^(0:16:63)),size(stream1,1),1),2,'native');
    else
        stream1 = [];
    end
    
    if(regs.PCKR.confEn)
        % | Cn+15 1'h|...|Cn+0 1'h|
        stream2 = buffer_(cstream(:),16)';
        stream2 = sum(uint64(stream2).*repmat(uint64(2.^(0:4:63)),size(stream2,1),1),2,'native');
    else
        stream2 = [];
    end
    
    
    if(regs.PCKR.irEn)
        % | In+7 2'h|...|In+0 2'h|
        stream3 =  buffer_(istream(:),8)';
        stream3 = sum(uint64(stream3).*repmat(uint64(2.^(0:8:63)),size(stream3,1),1),2,'native');
    else
        stream3 = [];
    end
    
end


if(~isempty(traceOutDir))
    Utils.buildTracer(dec2hexFast(stream1),'PCKR_stream_1',traceOutDir);
    Utils.buildTracer(dec2hexFast(stream2),'PCKR_stream_2',traceOutDir);
    Utils.buildTracer(dec2hexFast(stream3),'PCKR_stream_3',traceOutDir);
end


end

