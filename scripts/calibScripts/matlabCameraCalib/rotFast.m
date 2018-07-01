function [m] = rotFast(ang)
% rotation around y-axis
m = [
    1 0          0;
    0 cosd(ang) -sind(ang);
    0 sind(ang)  cosd(ang)
    ];
end

