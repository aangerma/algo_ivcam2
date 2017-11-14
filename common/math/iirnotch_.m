function [num,den] = iirnotch_(Wo,BW)

BW = BW*pi;
Wo = Wo*pi;

Gb   = sqrt(0.5);
beta = (sqrt(1-Gb.^2)/Gb)*tan(BW/2);
gain = 1/(1+beta);

num  = gain*[1 -2*cos(Wo) 1];
den  = [1 -2*gain*cos(Wo) (2*gain-1)];
