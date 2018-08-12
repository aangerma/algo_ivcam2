function [  ] = checkerboardInfoMessage( frame,fprintff )
warning('off','vision:calibrate:boardShouldBeAsymmetric'); % Supress checkerboard warning
[p,~] = detectCheckerboardPoints(normByMax(frame.i)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
fprintff('%d CB corners detected.\n',size(p,1));


end

