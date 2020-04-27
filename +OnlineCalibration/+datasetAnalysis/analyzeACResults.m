clear
close all
% Define params = 
analysisParams.optResultsPath = 'X:\IVCAM2_calibration _testing\analysisResults\20_April_22___23_39_bestAC1VersionSoFar\results.mat';
% analysisParams.optVars = 'KrgbRT';
analysisParams.optVars = 'PDecomposed';
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
    featuresMat = OnlineCalibration.aux.extractFeatures(desicionParams,analysisParams.optVars);
    
    % Classifiy scenes
    uvPre = [results.uvErrPre];
    if strcmp(analysisParams.optVars, 'KrgbRT')
        uvPost = [results.(['uvErrPostKRTOpt'])];
    else
        uvPost = [results.(['uvErrPost',analysisParams.optVars,'Opt'])];
    end
    labels = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPost,analysisParams.successFunc);
    labels(any(isnan(featuresMat),2),:) = [];
    featuresMat(any(isnan(featuresMat),2),:) = [];
    
    % Train SVM - For all params or just one
    svmTrain = @(feature,label) fitcsvm(feature,label,'KernelFunction','rbf',...
        'Standardize',true);
    SVMModel = svmTrain(featuresMat,labels);
    [newLabels,score] = predict(SVMModel,featuresMat);
    acc = mean(newLabels == labels);

    dataDir = fileparts(analysisParams.optResultsPath);
    SVMPath = fullfile(dataDir,'SVMModel.mat');
    save(SVMPath,'SVMModel');
    % Predicting linear SVM 
%     newLabels = (featuresMat-SVMModel.Mu)./SVMModel.Sigma*SVMModel.Beta+SVMModel.Bias > 0;
    
    
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
        splitedData = featuresMat(1:(end - mod(end,100)),:);
        splitedData = reshape(splitedData,[],nAugPerScene,size(featuresMat,2));
        splitedLabels = labels(1:(end - mod(end,100)));
        splitedLabels = reshape(splitedLabels,[],nAugPerScene);
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
