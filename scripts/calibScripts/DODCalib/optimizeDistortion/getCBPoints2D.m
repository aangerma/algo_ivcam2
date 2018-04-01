function [p] = getCBPoints2D(d)
% Finds checkerboard corners in the image.
[p,~] = detectCheckerboardPoints(normByMax(d.i)); % p - 3 checkerboard points. bsz - checkerboard dimensions.

end

