clear
close all
% Define params = 
analysisParams.optResultsPath = 'X:\IVCAM2_calibration _testing\analysisResults\20_April_08___17_00_comparingL1L2IDT\results.mat';
analysisParams.optVars = 'KdepthRT';
% analysisParams.optVars = 'P';
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
if size(results,2) < size(results,1) 
   allResults = results'; 
end
for i = 1:size(allResults,1)
    results = allResults(i,:);
    % Extract features
    desicionParams = [results.(['desicionParams',analysisParams.optVars])];

    edgeDistribution = [desicionParams.edgeWeightDistributionPerSectionDepth];
    features.edgeDistributionMaxOverMinDepth = max(edgeDistribution)./(min(edgeDistribution)+1e-3);

    edgeDistribution = [desicionParams.edgeWeightDistributionPerSectionRgb];
    features.edgeDistributionMaxOverMinRgb = max(edgeDistribution)./(min(edgeDistribution)+1e-3);

    edgeDirDistribution = reshape([desicionParams.edgeWeightsPerDir],4,[]);
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
    % Train SVM - For all params or just one
    svmTrain = @(feature,label) fitcsvm(feature,label,'KernelFunction','rbf',...
        'Standardize',true);
    SVMModel = svmTrain(featuresMat,labels);
    [newLabels,score] = predict(SVMModel,featuresMat);
    acc = mean(newLabels == labels);



    figure,
    subplot(2,4,[1,2,5,6])
    cm = confusionchart(labels,newLabels);
    xlabel('Valid Optimization');
    ylabel('"Good" UV Err');
    title(sprintf('acc = %2.2g',acc))
    extraTitles = {'True Negative';'False Positive';'False Negative';'True Positive'};
    pVec = [3,4,7,8];
    for i = 1:2
        for j = 1:2
            subplot(2,4,pVec(sub2ind([2, 2], i, j)));
            validPoints = logical((newLabels==i-1) .* (labels==j-1));
            plot(analysisParams.successFunc(:,1),analysisParams.successFunc(:,2),'linewidth',2);
            hold on 
            plot(uvPre(validPoints),uvPost(validPoints),'*');
            title(sprintf('%s %3.2g%%',extraTitles{sub2ind([2, 2], i, j)},mean(validPoints)*100));
            xlabel('UV Pre')
            ylabel('UV Post')
            grid on
            legend({'Success Line';'Scene Point'});
        end
    end

    %% Reference cross validation
    if analysisParams.performCrossValidation
        nOut = 0.2;
        nAugPerFrame = 100;
        splitedData = featuresMat(1:(end - mod(end,100)),:);
        splitedData = reshape(splitedData,[],nAugPerFrame,size(featuresMat,2));
        splitedLabels = labels(1:(end - mod(end,100)));
        splitedLabels = reshape(splitedLabels,[],nAugPerFrame);
        nTrain = ceil((1-nOut)*size(splitedData,1));
        nTest = size(splitedData,1) - nTrain;
        for i = 1:5
            testI = (1:nTest) + (i-1)*nTest;
            trainI = setdiff(1:size(splitedData,1),testI);

            trainSc = reshape(splitedData(trainI,:,:),[],size(featuresMat,2));
            testSc = reshape(splitedData(testI,:,:),[],size(featuresMat,2));
            trainLabels = vec(splitedLabels(trainI,:));
            testLabels = vec(splitedLabels(testI,:));

            SVMModelCV = svmTrain(trainSc,trainLabels);
            [newLabelsCV,~] = predict(SVMModelCV,testSc);
            accCV(i) = mean(newLabelsCV == testLabels);
        end
    end
    accCV
end
% Train SVM - For just one

% Show confusion matrix for each case with the chosen value
% [newLabels,score] = predict(SVMModel,featuresMat);

% mandatoryParams = 
% mandatory = {'gradITh';'gradZMax';'numSectionsV';'numSectionsH';'constantWeights';'constantWeightsValue'};
% nonmandatory = {'inverseDistParams';'maxStepSize';'tau';'controlParam';'edgeThresh4logicIm'};
