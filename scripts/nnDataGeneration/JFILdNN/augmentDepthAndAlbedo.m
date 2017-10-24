function [zImOut,aImOut] = augmentDepthAndAlbedo(zIm,aIm)
%AUGMENTDEPTHANDALBEDO 
% 1. randomly scales and translates the albedo image. a = a*[0.9,1.1]+[-0.1,0.1]
% 2. randomly scales and translates the depth image. z = z*[0.9,1.1]+[-200,200]

aMax = 1;
aMin = 0;
randScaleA = 1 + (rand/5-0.1);
randTransA = rand*0.2-0.1;


aImOut = randScaleA*aIm+randTransA;
aImOut(aImOut>aMax) = aMax;
aImOut(aImOut<aMin) = aMin;

zMin = 0;
randScaleZ = 1 + (rand/5-0.1);
randTransZ = rand*200-100;

zImOut = randScaleZ*zIm+randTransZ;
zImOut(zImOut<zMin) = zMin;

end

