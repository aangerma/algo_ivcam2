function  [data, results] = validationCalcAfterHeating(data,calibParams, fprintff, algoInternalDir, runParams)
data.dutyCycle2Conf = readtable(fullfile(algoInternalDir,'dutyCycle2Conf.csv'));
invalidFrames = arrayfun(@(x) isempty(x.ptsWithZ), data.framesData');
Invalid_Frames = sum(invalidFrames);
fprintff('Invalid frames: %.0f/%.0f\n', Invalid_Frames, numel(invalidFrames));
data.framesData = data.framesData(~invalidFrames);

data = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff,1);
results = data.results;
end
