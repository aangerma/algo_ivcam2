function [m] = rotSlow(ang)
% rotation around y-axis
m = [cosd(ang) 0 sind(ang);
     0         1         0;
     -sind(ang) 0 cosd(ang)
     ];
end

