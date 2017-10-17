function [ lutOut ] = genJFILgamma(  )
%% Generate a LUT for gamma function.

% 1. 12 bits in.
% 2. 8 bits out.
% 3. 64 values.

% GAMMA = 0.4;
% 
% X = linspace(0,1,65);
% lut = X.^(GAMMA);
% lut = lut*(2^8-1);
% lut=uint8(lut);

% lut = uint8((1-exp(-2*((0:64)/64)).^2)*255);
 lut = uint8(linspace(0,255,65));

% plot(linspace(0,4095,65),linspace(0,255,65),linspace(0,4095,65),lut);

lutOut.lut = lut;
lutOut.name = 'JFILgamma';
end



