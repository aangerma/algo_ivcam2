function [ hexOut ] = logical2hex( v )
%LOGICAL2UINT64 Summary of this function goes here
%   converts logical to hex

hexOut = flipud(reshape(flipud(dec2hexFast(v)'),16,[]))';

end

