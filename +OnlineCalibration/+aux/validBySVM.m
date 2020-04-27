function [isValid] = validBySVM(decisionParams,params)
load(params.svmModelPath);
featuresMat = OnlineCalibration.aux.extractFeatures(decisionParams);
isValid = predict(SVMModel,featuresMat);



end

