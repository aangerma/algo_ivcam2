function [I] = readGrayImage(imPath)
I = imread(imPath);
if size(I,3) > 1
    I = rgb2gray(I);
end

end

