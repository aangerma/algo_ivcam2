nLogs = sum(cellfun(@(x) length(x.mclogs), allData));
nSamples = nLogs*nSamplesInLog;
iSampleInLog = repmat((1:nSamplesInLog)', [nLogs,1]);
iLogInData = kron((1:nLogs)', ones(nSamplesInLog,1));
thetaH = zeros(nSamples, 1);
thetaV = zeros(nSamples, 1);
isExtrapolated = zeros(nSamples, 1);