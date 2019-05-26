function [estOutput, optCoefs, optDelay, delayedDesiredOutput, optStdPerDelay] = FitLinearModelWithDelay(inputMat, desiredOutput, testedDelays, isRelevantForFit)
% Finds optimal delay and coefficients for the linear model:
%   desiredOutput(t-optDelay) = inputMat * optCoefs
% where the metrics are computed only for samples relevant for fit

% preparations
nSamples = length(desiredOutput);
if (mod(nSamples,2) > 0)
    warning('FitLinearModeWithDelay: number of samples should be even')
end
if (nargin < 4)
    isRelevantForFit = true(nSamples, 1);
end
if (nargin < 3)
    testedDelays = 0;
end
A = inputMat(isRelevantForFit,:);

% finding optimal delay
nDelays = length(testedDelays);
optStdPerDelay = zeros(1,nDelays);
for iDelay = 1:nDelays
    delayFilterFft = BuildFractionalDelayFilter(testedDelays(iDelay), nSamples).';
    delayedDesiredOutput = ifft(fft(desiredOutput).*delayFilterFft); % note that we delay the output, to align it with input
    delayedDesiredOutput = delayedDesiredOutput(isRelevantForFit);
    optCoefs = (A'*A)\(A'*delayedDesiredOutput);
    estOutput = A*optCoefs;
    optStdPerDelay(iDelay) = std(estOutput-delayedDesiredOutput);
end
[~, minInd] = min(optStdPerDelay);
optDelay = testedDelays(minInd);

% finding optimal coefficients
delayFilterFft = BuildFractionalDelayFilter(optDelay, nSamples).';
delayedDesiredOutput = ifft(fft(desiredOutput).*delayFilterFft); % note that we delay the output, to align it with input
delayedDesiredOutput = delayedDesiredOutput(isRelevantForFit);
optCoefs = (A'*A)\(A'*delayedDesiredOutput);
estOutput = A*optCoefs;

