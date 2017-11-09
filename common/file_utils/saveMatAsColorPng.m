function [ ] = saveMatAsColorPng( image,name )
%SAVEMATASCOLORPNG Summary of this function goes here
%   Detailed explanation goes here
upper = max(image(:));
lower = min(image(:));
image = uint8(double(image - lower)*255/double(upper-lower));
imwrite(image,colormap('jet(256)'),name,'png')
end

