function [rotK] = rotateKMat(K,res)
%ROTATEKMAT Calculates the K that can be used on an image rotated by 180
%degrees that gets the same geometry (but with different signed X and Y
%values)
rotK = K;
rotK(1,3) = double(res(2))-1-rotK(1,3);
rotK(2,3) = double(res(1))-1-rotK(2,3);
end

