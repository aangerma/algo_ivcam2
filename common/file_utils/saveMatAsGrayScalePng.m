function [ ] = saveMatAsGrayScalePng( image,name,range )
    %SAVEMATASCOLORPNG Summary of this function goes here
    %   Detailed explanation goes here
    if exist('range','var')
        upper = range(2);
        lower = range(1);
    else
        upper = max(image(:));
        lower = min(image(:));
    end
    
    image = uint8(double(image - lower)*255/double(upper-lower));
    imwrite(image,colormap('gray(256)'),name,'png')
end