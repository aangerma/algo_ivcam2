function [isValid] = linearSVM(decisionParams,svmParams)
% This function gets:
% svmParams - global parameters
% decisionParams - some metrics collected spesifically from the scene. Some
% from before and some after the optimization.
% Returns "isvalid" - 1 if the scene is valid 0 if we should discard the
% optimization result
featuresVec = extractFeatures(decisionParams);
isValid = predict(featuresVec,svmParams);
end

function featuresVec = extractFeatures(decisionParams)


    edgeDistribution = decisionParams.edgeWeightDistributionPerSectionDepth;
    features.edgeDistributionMinOverMaxDepth = min(edgeDistribution)./(max(edgeDistribution)+1e-6);
    featuresVec(1) = features.edgeDistributionMinOverMaxDepth;
    
    edgeDistribution = decisionParams.edgeWeightDistributionPerSectionRgb;
    features.edgeDistributionMinOverMaxRgb = min(edgeDistribution)./(max(edgeDistribution)+1e-6);
    featuresVec(2) = features.edgeDistributionMinOverMaxRgb;

    edgeDirDistribution = decisionParams.edgeWeightsPerDir;
    features.edgeDirDistributionMinOverMaxPerp = min(edgeDirDistribution([1,3]))./(max(edgeDirDistribution([1,3]))+1e-6);
    featuresVec(3) = features.edgeDirDistributionMinOverMaxPerp;
    features.edgeDirDistributionMinOverMaxDiag = min(edgeDirDistribution([2,4]))./(max(edgeDirDistribution([2,4]))+1e-6);
    featuresVec(4) = features.edgeDirDistributionMinOverMaxDiag;

    features.initialCost = decisionParams.initialCost;
    featuresVec(5) = features.initialCost;
    features.finalCost = decisionParams.newCostP;
    featuresVec(6) = features.finalCost;

    features.xyMovement = decisionParams.xyMovement;
    features.xyMovement(features.xyMovement > 100) = 100;
    featuresVec(7) = features.xyMovement;
    features.xyMovementFromOrigin = decisionParams.xyMovementFromOrigin;
    features.xyMovementFromOrigin(features.xyMovementFromOrigin > 100) = 100;
    featuresVec(8) = features.xyMovementFromOrigin;
    features.minImprovementPerSection = decisionParams.minImprovementPerSection;
    featuresVec(9) = features.minImprovementPerSection;
    features.maxImprovementPerSection = decisionParams.maxImprovementPerSection;
    featuresVec(10) = features.maxImprovementPerSection;
    
end
function isValid = predict(featuresVec,svmParams)
featuresVec = reshape(featuresVec,1,[]);
featuresNormalized = (featuresVec - svmParams.Mu)./svmParams.Sigma;
isValid = (featuresNormalized*svmParams.W' + svmParams.Bias) > 0;
end

