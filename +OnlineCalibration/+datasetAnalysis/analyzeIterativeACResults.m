clear
close all
% Define params = 
analysisParams.optResultsPath = 'X:\IVCAM2_calibration _testing\analysisResults\\20_May_17___03_02_AC2_Iterative_Status\results.mat';

analysisParams.performCrossValidation = 0;
analysisParams.successFunc = [0,2;...
                              1,2;...
                              3,3;...
                              5,4;...
                              7,4;...
                              9,5;...
                              12,6;...
                              100,6];
analysisParams.svmMethod = 'linear'; % 'rbf', 'linear'

% Load dataset optimization results
load(analysisParams.optResultsPath);

    
% Classifiy scenes
uvPre = [results.uvErrPre];
gidPre = getFields(results,'metricsPre','gid');

for k = 1:numel(results)
    uvPost(k) = results(k).uvErrPostK2DSM(end);
    gidPost(k) = results(k).gidPostK2DSM(end);
end

labelsGT = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPost,analysisParams.successFunc)';
labelsActual = [results.validFixBySVM];
OnlineCalibration.datasetAnalysis.plotResults(labelsGT,labelsActual,uvPre,uvPost,gidPre,gidPost,analysisParams);
successRate = mean(labelsGT);

uvPostKz = [results.uvErrPostKzFromPOpt];
gidPostKz = getFields(results,'metricsPostKzFromP','gid');
labelsGT = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPostKz,analysisParams.successFunc)';
OnlineCalibration.datasetAnalysis.plotResults(labelsGT,labelsActual,uvPre,uvPostKz,gidPre,gidPostKz,analysisParams);
successRateKz = mean(labelsGT);

figure;
histogram(gidPost);
hold on
histogram(gidPostKz);
legend({'gidK2DSM';'gidKdepth'});
xlabel('GID[mm]')

figure;
plot(gidPre,gidPost,'r*');
hold on
plot(gidPre,gidPostKz,'g*');
plot(gidPre,gidPre);
legend({'gidK2DSM';'gidKdepth'});
xlabel('GID pre[mm]')
ylabel('GID post[mm]')
axis equal

dg = 1;
qVec = 1:dg:10;
[~,mem] = min(abs(gidPre'-qVec),[],2);
for i = 1:max(mem(:))
    inds = mem == i;
    gidK2DSMQ(i) = mean(gidPost(inds));
    gidKdepthQ(i) = mean(gidPostKz(inds));
end
figure;
bar([gidK2DSMQ;gidKdepthQ]');
legend({'gidK2DSM';'gidKdepth'});
grid minor
title('Mean GID Post Quantized')
%% Train SVM - For all params or just one
svmTrain = @(feature,label) fitcsvm(feature,label,'KernelFunction',analysisParams.svmMethod,...
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
