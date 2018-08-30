function [  ] = checkerboardInfoMessage( frame,fprintff ,th )
warning('off','vision:calibrate:boardShouldBeAsymmetric'); % Supress checkerboard warning
[p,~] = Calibration.aux.CBTools.findCheckerboard(normByMax(double(frame.i)), [9,13]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
if size(p,1)<th
    fprintff('%d/%d CB corners detected.\n',size(p,1),th);
end


end

