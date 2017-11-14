function n=sprivSizeof(sizestr)

switch(sizestr)
    case 'double'
        n=64;
    case 'single'
        n=32;
    case 'float'
        n=32;
    case 'uint2'
        n = 2;
    case 'uint4'
        n = 4;
    case 'uint8'
        n=8;
    case 'int8'
        n=8;
    case 'int10'
        n=10;
    case 'uint12'
        n=12;
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





