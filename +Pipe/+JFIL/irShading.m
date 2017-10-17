function jStream=irShading(jStream, regs, luts,instance,lgr,traceOutDir)



if(~regs.JFIL.irShadingBypass)
    %%
    ir = jStream.ir;
    shadingLUT = cumsum([int16(regs.JFIL.irShadingLUTr0(1:17));reshape(regs.JFIL.irShadingLUTdelta,16,17)]);
    
    
    %x-11b,y-10b
    [yg,xg]=ndgrid(0:size(ir,1)-1,0:size(ir,2)-1);
    xg = uint16(vec(xg));yg = uint16(vec(yg));
    
    %16b
    
    %x-15b,y-14b
    xxg = bitshift(uint32(xg)*uint32(regs.JFIL.irShadingScale(1))+2^7,-8);
    yyg = bitshift(uint32(yg)*uint32(regs.JFIL.irShadingScale(2))+2^7,-8);
    %take lower 10b (after bitshift there shoudn't be any data bigger than that);
    assert(all(vec(bitshift(xxg,-10)==0)));
    assert(all(vec(bitshift(yyg,-10)==0)));
    %top 4 bit selects index
    xindx=bitshift(xxg,-6);
    yindx=bitshift(yyg,-6);
    %bottom 6 gives interpolation
    dx = bitand(xxg,2^6-1);%6b
    dy = bitand(yyg,2^6-1);%6b
    bx = (64-dx);%7b
    by = (64-dy);%7b
    s2i=@(i,j) sub2ind([17 17],yindx+j+1,xindx+i+1);
    lutIndices = [s2i(0,0) s2i(0,1) s2i(1,0) s2i(1,1)];
    weights =     [bx.*by   bx.*dy     dx.*by     dx.*dy ];%sum==4096
    bilVals = shadingLUT(lutIndices); %4x12b
    wv = uint32(weights).*uint32(bilVals);%[26b 25b 25b 24b]
    wv = sum(wv,2,'native');%24b
    wv = bitshift(wv,-12);%14b
    wv = reshape(wv,size(ir));
    irout=bitshift(uint64(wv).*uint64(ir),-11);%14b
    irout=uint16(min(irout,2^12-1));%12b (saturation)
    
    %%
    jStream.ir=irout;
end

Pipe.JFIL.checkStreamValidity(jStream,instance,false);
if(~isempty(traceOutDir) )
    Utils.buildTracer(dec2hexFast(jStream.ir,3),['JFIL_' instance],traceOutDir);
end




end