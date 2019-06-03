function [score, results ] = validateConfidence( hw )
% Disable confidence invalidation in the JFIL block 
% Set a confidence configuration
% Take 100 frames of a static scene
% For each pixel, calculate its temporal noise/zSTD
% Calculate the accuracy
temporalNoise = 3;
zStdTh = 3*temporalNoise;

hw.cmd('DIRTYBITBYPASS');
hw.setReg('JFILinvBypass',1)

frames = hw.getFrame(100,0);
zMaxSubMM = hw.z2mm;
confTh = hw.read('JFILinvConfThr');


Z = cat(3, frames.z);
Z = double(Z);
Z(Z==0) = nan;
noiseStd = nanstd(double(Z)/double(zMaxSubMM), 0, 3);
C = cat(3, frames.c);
C = double(C);
C(Z==0) = nan;
cMean = namean(C);

invalidated = cMean < confTh;

goodPixels = noiseStd < zstdTh;
badPixels = ~goodPixels;

labeledCorrectly = goodPixels & ~invalidated | (~goodPixels) & invalidated;
results.acc = mean(vec(labeledCorrectly));
results.truePositiveRate = sum(vec(goodPixels & ~invalidated)) / sum(vec(goodPixels));
results.falsePositiveRate = 1 - results.truePositiveRate;
results.trueNegativeRate = sum(vec(badPixels & invalidated)) / sum(vec(badPixels));
results.falseNegativeRate = 1 - results.trueNegativeRate;

results.positivePredictiveValue = sum(vec(goodPixels & ~invalidated)) / sum(vec(~invalidated));
results.F1Score = 2*(results.positivePredictiveValue*results.truePositiveRate)/(results.positivePredictiveValue+results.truePositiveRate);
end

