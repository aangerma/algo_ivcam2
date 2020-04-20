clear
close all
% Define params = 
analysisParams.optResultsPath = 'X:\IVCAM2_calibration _testing\analysisResults\20_March_29___19_03\results.mat';
% analysisParams.optVars = 'KdepthRT';
analysisParams.optVars = 'P';
analysisParams.performCrossValidation = 1;
analysisParams.successFunc = [0,2;...
                              1,2;...
                              3,3;...
                              5,4;...
                              7,4;...
                              9,5;...
                              12,6;...
                              100,6];

% Load dataset optimization results
load(analysisParams.optResultsPath);

% Extract features
desicionParams = [results.(['desicionParams',analysisParams.optVars])];

edgeDistribution = [desicionParams.edgeWeightDistributionPerSectionDepth];
features.edgeDistributionMaxOverMinDepth = max(edgeDistribution)./(min(edgeDistribution)+1e-3);

edgeDistribution = [desicionParams.edgeWeightDistributionPerSectionRgb];
features.edgeDistributionMaxOverMinRgb = max(edgeDistribution)./(min(edgeDistribution)+1e-3);

edgeDirDistribution = [desicionParams.edgeWeightsPerDir];
features.edgeDirDistributionMaxOverMinPerp = max(edgeDirDistribution([1,3],:))./(min(edgeDirDistribution([1,3],:))+1e-3);
features.edgeDirDistributionMaxOverMinDiag = max(edgeDirDistribution([2,4],:))./(min(edgeDirDistribution([2,4],:))+1e-3);

features.initialCost = [desicionParams.initialCost];
features.finalCost = [desicionParams.(['newCost',analysisParams.optVars])];

features.xyMovement = [desicionParams.xyMovement];
features.xyMovementFromOrigin = [desicionParams.xyMovementFromOrigin];

improvementPerSection = reshape([desicionParams.improvementPerSection]',4,[]); 
improvementPerSectionPositive = improvementPerSection;
improvementPerSectionPositive(improvementPerSectionPositive<0) = 0;
features.sumOfPositiveImprovement = sum(improvementPerSectionPositive);

improvementPerSectionNegative = improvementPerSection;
improvementPerSectionNegative(improvementPerSectionNegative>0) = 0;
features.sumOfNegativeImprovement = sum(improvementPerSectionNegative);

featureNames = fieldnames(features);
featuresMat = zeros(numel(featureNames),numel(results));
for f = 1:numel(featureNames)
    featuresMat(f,:) = features.(featureNames{f});
end
featuresMat = featuresMat';
% Classifiy scenes
uvPre = [results.uvErrPre];
uvPost = [results.(['uvErrPost',analysisParams.optVars,'Opt'])];
labels = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPost,analysisParams.successFunc);


figure;
for i = 1:size(featuresMat,2)
   feat = featuresMat(:,i);
   lab = labels;
   lab(isnan(feat)) = [];
   feat(isnan(feat)) = [];
   grd = [linspace(min(feat),median(feat),20),linspace(median(feat),max(feat),20)];
   [~,mi] = min(abs(feat-grd),[],2);
   for j = 1:numel(grd)
       if any(mi==j)
           La(j) = mean(lab(mi==j));
       end
        
   end
   tabplot;
   scatter(grd,La);
   title(featureNames{i})
end

