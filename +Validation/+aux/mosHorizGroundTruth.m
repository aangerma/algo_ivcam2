function [width, height] = mosHorizGroundTruth(bigUp)

height = [
    1 1 1 1;
    1 1 1 1;
    2 2 2 2;
    2 2 2 2;
    4 4 4 4;
    4 4 4 4;
    8 8 8 8;
    8 8 8 8
    ];

width = [
    4 3 2 1;
    8 7 6 5;
    4 3 2 1;
    8 7 6 5;
    4 3 2 1;
    8 7 6 5;
    4 3 2 1;
    8 7 6 5;
    ];

if ~exist('bigUp','var')
    bigUp = true;
end

if (bigUp)
    height = rot90(height, 2);
    width = rot90(width, 2);
end

end


