function [ integralImg ] = integralImage( img )
% for an input image img, return the integral image integralImage.

% Maximum possible value for the integral image is 160X120X255 = 4896000.
% log2 of 4896000 is 22.22 so we need 23 bits.

NUMBER_OF_BITS_FOR_THE_ACCUMULATOR = 23;
MAXIMUM_VALUE = 2^NUMBER_OF_BITS_FOR_THE_ACCUMULATOR -1;


integralVertical = uint32(cumsum(img,1));
integralImg= uint32(cumsum(integralVertical,2));
integralImg(integralImg >= MAXIMUM_VALUE) = MAXIMUM_VALUE;
end

