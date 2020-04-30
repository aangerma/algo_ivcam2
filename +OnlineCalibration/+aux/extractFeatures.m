function [featuresMat] = extractFeatures(desicionParams, optVars)
    edgeDistribution = [desicionParams.edgeWeightDistributionPerSectionDepth];
    features.edgeDistributionMaxOverMinDepth = max(edgeDistribution)./(min(edgeDistribution)+1e-3);

    edgeDistribution = [desicionParams.edgeWeightDistributionPerSectionRgb];
    features.edgeDistributionMaxOverMinRgb = max(edgeDistribution)./(min(edgeDistribution)+1e-3);

    edgeDirDistribution = reshape([desicionParams.edgeWeightsPerDir],4,[]);
    features.edgeDirDistributionMaxOverMinPerp = max(edgeDirDistribution([1,3],:))./(min(edgeDirDistribution([1,3],:))+1e-3);
    features.edgeDirDistributionMaxOverMinDiag = max(edgeDirDistribution([2,4],:))./(min(edgeDirDistribution([2,4],:))+1e-3);

    features.initialCost = [desicionParams.initialCost];
    features.finalCost = [desicionParams.(['newCostP'])];
    

    features.xyMovement = [desicionParams.xyMovement];
    features.xyMovement(features.xyMovement > 100) = 100;
    features.xyMovementFromOrigin = [desicionParams.xyMovementFromOrigin];
    features.xyMovementFromOrigin(features.xyMovementFromOrigin > 100) = 100;

    improvementPerSection = reshape([desicionParams.improvementPerSection]',4,[]); 
    improvementPerSectionPositive = improvementPerSection;
    improvementPerSectionPositive(improvementPerSectionPositive<0) = 0;
    features.sumOfPositiveImprovement = sum(improvementPerSectionPositive);

    improvementPerSectionNegative = improvementPerSection;
    improvementPerSectionNegative(improvementPerSectionNegative>0) = 0;
    features.sumOfNegativeImprovement = sum(improvementPerSectionNegative);

    featureNames = fieldnames(features);
    featuresMat = zeros(numel(featureNames),numel(desicionParams));
    for f = 1:numel(featureNames)
        featuresMat(f,:) = features.(featureNames{f});
    end
    featuresMat = featuresMat';
end

