function [params] = getParamsForAC(params)
params.inverseDistParams.alpha = 1/3;
% params.inverseDistParams.gamma = 0.98;
params.inverseDistParams.gamma = 0.9;

params.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
params.gradITh = 3.5; % Ignore pixels with IR grad of less than this
if all(params.depthRes == [768,1024])
    params.gradITh = 1.5; % Ignore pixels with IR grad of less than this for XGA?
end
params.gradZTh = 25; % Ignore pixels with Z grad of less than this
params.gradZMax = 1000; 
params.maxStepSize = 1;
params.tau = 0.5;
params.controlParam = 0.5;
params.minStepSize = 1e-5;
params.maxBackTrackIters = 50;
params.minRgbPmatDelta = 1e-5;
params.minCostDelta = 1;
params.maxOptimizationIters = 50;
params.zeroLastLineOfPGrad = 1;
params.constLastLineOfP = 0;

% params.rgbPmatNormalizationMat = [0.35682896, 0.26685065,1.0236474,0.00068233482; 0.35521242, 0.26610452, 1.0225836, 0.00068178622; 410.60049, 318.23358, 1205.4570, 0.80363423];
params.rgbPmatNormalizationMat = [0.35369244,0.26619774,1.0092601,0.00067320449;0.35508525,0.26627505,1.0114580,0.00067501375;414.20557,313.34106,1187.3459,0.79157025];
params.KrgbMatNormalizationMat = [0.35417202,0.26565930,1.0017655;0.35559174,0.26570305,1.0066491;409.82886,318.79565,1182.6952];
params.RnormalizationParams = [1508.9478;1604.9430;649.38434];
params.TmatNormalizationMat = [0.91300839;0.91698289;0.43305457];
params.edgeThresh4logicIm = 0.1;
params.seSize = 3;
params.moveThreshPixVal = 20;
params.moveThreshPixNum =  3e-05*prod(params.rgbRes);
params.moveGaussSigma = 1;
params.maxXYMovementPerIteration = [10,2,2]*prod(params.rgbRes)/(1920*1080);
params.maxXYMovementFromOrigin = 20*prod(params.rgbRes)/(1920*1080);
params.numSectionsV = 2;
params.numSectionsH = 2;
params.gradDirRatio = 10;
params.gradDirRatioPerp = 1.5;

params.edgeDistributMinMaxRatio = 0.005;
params.minWeightedEdgePerSectionDepth = 50*(480*640)/prod(params.depthRes);
params.minWeightedEdgePerSectionRgb = 0.05*(1920*1080)/prod(params.rgbRes);
end

