function [ frame ] = rotFrame180( frame )
%ROTFRAME180 Summary of this function goes here
%   Detailed explanation goes here
fnames = fieldnames(frame);

for f = 1:numel(fnames)
    frame.(fnames{f}) = rot90(frame.(fnames{f}),2);
    
end

end

