function [E,Ix,Iy] = edgeSobelXY(I)
[Ix,Iy] = imgradientxy(I);% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]
Ix = Ix/8;
Iy = Iy/8;
mask = zeros(size(Ix));
mask(2:end-1,2:end-1) = 1;
Ix(~mask) = 0;
Iy(~mask) = 0;
%E = single(sqrt(Ix.^2+Iy.^2));
E = double(sqrt(Ix.^2+Iy.^2));
end

