function [ frames ] = rotFrame180( frames )
for i = 1:numel(frames)
    frames(i).i = rot90(frames(i).i,2);
    frames(i).z = rot90(frames(i).z,2);
    frames(i).c = rot90(frames(i).c,2);
end


end

