function lutOut = vec2lutData(v,nbits)
if(~exist('nbits','var'))
    nbits=8;
end
if(isa(v,'double') || isa(v,'single'))
    v = single(v);
else
    v = uint32(v);
end
lutOut=dec2hex(typecast(v(:),'uint32'),nbits);
lutOut = [lutOut 10*ones(size(lutOut,1),1)];
lutOut=vec(lutOut')';
end