function [  ] = checkerboardInfoMessage( frame,fprintff ,th )
warning('off','vision:calibrate:boardShouldBeAsymmetric'); % Supress checkerboard warning
CB = CBTools.Checkerboard (normByMax(double(frame.i)),'expectedGridSize',[9,13]);  
pt = CB.getGridPointsList;
if size(pt,1)<th
    fprintff('%d/%d CB corners detected.\n',size(p,1),th);
end

end

