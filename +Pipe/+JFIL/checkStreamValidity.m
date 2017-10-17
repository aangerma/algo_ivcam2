function checkStreamValidity(jStream,instance,allowInvalidPixels)
vdpth = jStream.depth~=0;
vconf = jStream.conf ~=0;
invPix = bitxor(vdpth,vconf);
if(any(invPix(:)))
    [y,x]=find(invPix,1);
    error('JFIL::%s Invalid depth/confidence combination(%d,%d): depth=%d, confidence =%d',instance,x,y,jStream.depth(y,x),jStream.conf(y,x));
end
if(~allowInvalidPixels && any(vec(~vconf & ~vdpth)))
    %scan holes bigger than 3x3 is quite frequent
    %warning( 'Invalid pixels are not premitted in this section of the JFIL flow(%s)',instance);
    
end
if(any(jStream.conf(:)~=0 & jStream.depth(:)~=0 & jStream.ir(:)==0))
%      warning( 'valid pixelwith no IR(%s)',instance);
end
assert(nnz(jStream.conf>2^4-1)==0,'confidence value should be smaller than 15(%s)',instance);
assert(nnz(jStream.ir>2^12-1)==0,'ir value should be smaller than 4095(%s)',instance);

end