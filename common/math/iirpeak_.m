function [num,den] = iirpeak_(Wo,BW)


BW = BW*pi;
Wo = Wo*pi;
Ab = abs(10*log10(.5)); % 3-dB widt
Gb   = 10^(-Ab/20);
beta = (Gb/sqrt(1-Gb.^2))*tan(BW/2);
gain = 1/(1+beta);

num  = (1-gain)*[1 0 -1];
den  = [1 -2*gain*cos(Wo) (2*gain-1)];
end