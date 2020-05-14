clear
close all
% Define params = 
analysisParams.optResultsPath = 'X:\IVCAM2_calibration _testing\analysisResults\\20_April_29___15_13_AC2_Status\results.mat';
% analysisParams.optVars = 'KrgbRT';
analysisParams.optVars = 'KzFromP';
% analysisParams.optVars = '';
analysisParams.performCrossValidation = 0;
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
allResults = results;
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
    gidPre = [results.metricsPre]; gidPre = [gidPre.gid];
    if strcmp(analysisParams.optVars, 'KrgbRT')
        uvPost = [results.(['uvErrPostKRTOpt'])];
    else
        uvPost = [results.(['uvErrPost',analysisParams.optVars,'Opt'])];
        gidPost = [results.metricsPostKzFromP]; gidPost = [gidPost.gid];
    end
    labels = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPost,analysisParams.successFunc);
    
%     gidPre(any(isnan(featuresMat),2)) = [];
%     gidPost(any(isnan(featuresMat),2)) = [];
%     uvPre(any(isnan(featuresMat),2)) = [];
%     uvPost(any(isnan(featuresMat),2)) = [];
%     labels(any(isnan(featuresMat),2),:) = [];
%     featuresMat(any(isnan(featuresMat),2),:) = [];
    
    % Train SVM - For all params or just one
    svmTrain = @(feature,label) fitcsvm(feature,label,'KernelFunction','rbf',...
        'Standardize',true);
    SVMModel = svmTrain(featuresMat,labels);
    [newLabels,score] = predict(SVMModel,featuresMat);
    OnlineCalibration.datasetAnalysis.plotResults(labels,newLabels,uvPre,uvPost,gidPre,gidPost,analysisParams);
    
    dataDir = fileparts(analysisParams.optResultsPath);
    SVMPath = fullfile(dataDir,'SVMModel.mat');
    save(SVMPath,'SVMModel');
    % Predicting linear SVM 
%     newLabels = (featuresMat-SVMModel.Mu)./SVMModel.Sigma*SVMModel.Beta+SVMModel.Bias > 0;
    
    
    
    
    
    
    %% Reference cross validation
    if analysisParams.performCrossValidation
        nOut = 0.2;
        splitedData = featuresMat(1:(end - mod(end,nAugPerScene)),:);
        splitedData = reshape(splitedData,[],nAugPerScene,size(featuresMat,2));
        splitedLabels = labels(1:(end - mod(end,nAugPerScene)));
        splitedLabels = reshape(splitedLabels,[],nAugPerScene);
        uvPreCV = uvPre(1:(end - mod(end,nAugPerScene)));
        uvPreCV = reshape(uvPreCV,[],nAugPerScene);
        uvPostCV = uvPost(1:(end - mod(end,nAugPerScene)));
        uvPostCV = reshape(uvPostCV,[],nAugPerScene);
        gidPreCV = gidPre(1:(end - mod(end,nAugPerScene)));
        gidPreCV = reshape(gidPreCV,[],nAugPerScene);
        gidPostCV = gidPost(1:(end - mod(end,nAugPerScene)));
        gidPostCV = reshape(gidPostCV,[],nAugPerScene);
        nTrain = ceil((1-nOut)*size(splitedData,1));
        nTest = size(splitedData,1) - nTrain;
        for k = 1:5
            testI = (1:nTest) + (k-1)*nTest;
            trainI = setdiff(1:size(splitedData,1),testI);

            trainSc = reshape(splitedData(trainI,:,:),[],size(featuresMat,2));
            testSc = reshape(splitedData(testI,:,:),[],size(featuresMat,2));
            trainLabels = vec(splitedLabels(trainI,:));
            testLabels = vec(splitedLabels(testI,:));

            SVMModelCV = svmTrain(trainSc,trainLabels);
            [newLabelsCV,~] = predict(SVMModelCV,testSc);
            accCV(k) = mean(newLabelsCV == testLabels);
            
%             figure(100);tabplot(i);
%             cm = confusionchart(testLabels,newLabelsCV);
%             xlabel('Valid Optimization');
%             ylabel('"Good" UV Err');
%             title(sprintf('acc = %2.2g',accCV(i)))
            
            
            OnlineCalibration.datasetAnalysis.plotResults(testLabels,newLabelsCV,vec(uvPreCV(testI,:)),vec(uvPostCV(testI,:)),vec(gidPreCV(testI,:)),vec(gidPostCV(testI,:)),analysisParams);
        end
        accCV;
    end
    
end
% Train SVM - For just one

% Show confusion matrix for each case with the chosen value
% [newLabels,score] = predict(SVMModel,featuresMat);

% mandatoryParams = 
% mandatory = {'gradITh';'gradZMax';'numSectionsV';'numSectionsH';'constantWeights';'constantWeightsValue'};
% nonmandatory = {'inverseDistParams';'maxStepSize';'tau';'controlParam';'edgeThresh4logicIm'};
