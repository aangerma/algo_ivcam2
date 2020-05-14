function [isValid] = validBySVM(decisionParams,params)
load(params.svmModelPath);
featuresMat = OnlineCalibration.aux.extractFeatures(decisionParams);
isValid = predict(SVMModel,featuresMat);
% isValid = OnlineCalibration.aux.svmRbfPredictor(SVMModel, featuresMat); % Our matlab implementation of the predict function

% The following line verify the svmRbfPredictor function returns the same
% output as the matlab predict function. No need to implement this in LibRealSense 
assert(all(isValid == predict(SVMModel,featuresMat)),'Matlab implementation should be identical to our implementation');



end

