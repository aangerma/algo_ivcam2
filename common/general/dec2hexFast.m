function out=dec2hexFast(v,nNibbles)
v=vec(v);

if(islogical(v))
    v = uint8(sum(reshape(v,8,[]).*repmat(2.^(0:7).',1,length(v)/8)));
end
n = sizeof(v)/4;
if(nargin<2)
    nNibbles=n;
end
if(isa(v,'double'))
    v=uint64(v);
end
dec2dblnibLUT=dec2hex(0:255,2)';% '00'-'FF' LUT
out= flipud(reshape(         flipud(dec2dblnibLUT(:,uint16(typecast(v,'uint8'))+1))         ,n,[]))'; %uint16 just for overflow
out = out(:,end-nNibbles+1:end);



end


function n=sizeof(c)
switch(class(c))
    case 'double'
        n=64;
    case 'single'
        n=32;
    case 'float'
        n=32;
    case 'uint8'
        n=8;
    case 'int8'
        n=8;
    case 'uint16'
        n=16;
    case 'int16'
        n=16;
    case 'uint32'
        n=32;
    case 'int32'
        n=32;
    case 'uint64'
        n=64;
    case 'int64'
        n=64;
    case 'logical'
        n=1;
    otherwise
        error('unsopported class');
end

end
