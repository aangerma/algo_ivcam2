function [ out64 ] = logical2uint64( v )
%LOGICAL2UINT64 Summary of this function goes here
%   converts logical to uint64

u8 = sum(bsxfun(@times,uint8(reshape(v, 8, [])),uint8(2.^(0:7)')),'native');
out64 = typecast(u8, 'uint64');

end

