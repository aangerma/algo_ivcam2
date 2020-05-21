function [isValid,featuresMat] = validBySVM(decisionParams,params,outputBinFilesPath)
load(params.svmModelPath);
featuresMat = OnlineCalibration.aux.extractFeatures(decisionParams);





OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'featuresMat',double(featuresMat),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'featuresMat_trans',double(transpose(featuresMat)),'double');

OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightDistributionPerSectionDepth',double(decisionParams.edgeWeightDistributionPerSectionDepth),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightDistributionPerSectionRgb',double(decisionParams.edgeWeightDistributionPerSectionRgb),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'edgeWeightsPerDir',double(decisionParams.edgeWeightsPerDir),'double');
OnlineCalibration.aux.saveBinImage(outputBinFilesPath,'improvementPerSection',double(decisionParams.improvementPerSection),'double');

switch SVMModel.KernelParameters.Function
    case 'linear'
        isValid = (featuresMat-SVMModel.Mu)./SVMModel.Sigma*SVMModel.Beta+SVMModel.Bias > 0;
    case 'gaussian'
        isValid = OnlineCalibration.aux.svmRbfPredictor(SVMModel, featuresMat); % Our matlab implementation of the predict function
    otherwise
        error('Unknown SVM kernel %s',SVMModel.KernelParameters.Function);
end

% The following line verify the svmRbfPredictor function returns the same
% output as the matlab predict function. No need to implement this in LibRealSense 
assert(all(isValid == predict(SVMModel,featuresMat)),'Matlab implementation should be identical to our implementation');



end

