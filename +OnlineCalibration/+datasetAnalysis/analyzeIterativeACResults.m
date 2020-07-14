clear
close all
% Define params = 
analysisParams.testName = '20_June_03___23_04_AC2_Status_OnCheckers';
analysisParams.optResultsPath = fullfile('X:\IVCAM2_calibration _testing\analysisResults',analysisParams.testName,'results.mat');

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
gidPre = [results.gidPre];
scalePreH = [results.scaleErrorHPre];
scalePreV = [results.scaleErrorVPre];
for k = 1:numel(results)
    uvPost(k) = results(k).uvErrPostK2DSM(end);
    gidPost(k) = results(k).gidPostK2DSM(end);
    scaleH(k) = results(k).scaleErrorHPostK2DSM(end);
    scaleV(k) = results(k).scaleErrorVPostK2DSM(end);
end


labelsGT = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPost,analysisParams.successFunc)';
params.svmModelPath = fullfile(ivcam2root,'+OnlineCalibration','+SVMModel','SVMModelLinear.mat');
decisionParams = [results.(['desicionParams'])];
load(params.svmModelPath);
[featuresMat] = OnlineCalibration.aux.extractFeatures(decisionParams);
distanceFromPlane = (featuresMat-SVMModel.Mu)./SVMModel.Sigma*SVMModel.Beta+SVMModel.Bias;
labelsActual = distanceFromPlane' > 0;

labelsGT = gidPost<gidPre;

metricViz(1).pre = uvPre;
metricViz(1).post = uvPost;
metricViz(1).name = 'UV';
metricViz(1).units = 'pix';

metricViz(2).pre = gidPre;
metricViz(2).post = gidPost;
metricViz(2).name = 'GID';
metricViz(2).units = 'mm';

metricViz(3).pre = scalePreH;
metricViz(3).post = scaleH;
metricViz(3).name = 'ScaleH';
metricViz(3).units = 'prc';

metricViz(4).pre = scalePreV;
metricViz(4).post = scaleV;
metricViz(4).name = 'ScaleV';
metricViz(4).units = 'prc';

OnlineCalibration.robotAnalysis.plotResultMetrics(labelsGT,labelsActual,metricViz);

% 
% uvPostKz = [results.uvErrPostKzFromPOpt];
% gidPostKz = getFields(results,'metricsPostKzFromP','gid');
% labelsGT = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPostKz,analysisParams.successFunc)';
% OnlineCalibration.datasetAnalysis.plotResults(labelsGT,labelsActual,uvPre,uvPostKz,gidPre,gidPostKz,analysisParams);
% successRateKz = mean(labelsGT);
% 
% figure;
% histogram(gidPost);
% hold on
% histogram(gidPostKz);
% legend({'gidK2DSM';'gidKdepth'});
% xlabel('GID[mm]')
% 
% figure;
% plot(gidPre,gidPost,'r*');
% hold on
% plot(gidPre,gidPostKz,'g*');
% plot(gidPre,gidPre);
% legend({'gidK2DSM';'gidKdepth'});
% xlabel('GID pre[mm]')
% ylabel('GID post[mm]')
% axis equal
% 
% dg = 1;
% qVec = 1:dg:10;
% [~,mem] = min(abs(gidPre'-qVec),[],2);
% for i = 1:max(mem(:))
%     inds = mem == i;
%     gidK2DSMQ(i) = mean(gidPost(inds));
%     gidKdepthQ(i) = mean(gidPostKz(inds));
% end
% figure;
% bar([gidK2DSMQ;gidKdepthQ]');
% legend({'gidK2DSM';'gidKdepth'});
% grid minor
% title('Mean GID Post Quantized')
%% Train SVM - For all params or just one

desicionParams = [results.(['desicionParams'])];
featuresMat = OnlineCalibration.aux.extractFeatures(desicionParams,[]);
featuresMat(:,8) = [];


gidPre(any(isnan(featuresMat),2)) = [];
gidPost(any(isnan(featuresMat),2)) = [];
uvPre(any(isnan(featuresMat),2)) = [];
uvPost(any(isnan(featuresMat),2)) = [];
labelsGT(any(isnan(featuresMat),2)) = [];
featuresMat(any(isnan(featuresMat),2),:) = [];

svmTrain = @(feature,label) fitcsvm(feature,label,'KernelFunction',analysisParams.svmMethod,...
    'Standardize',false);
SVMModel = svmTrain(featuresMat,labelsGT);
[newLabels,score] = predict(SVMModel,featuresMat);
OnlineCalibration.datasetAnalysis.plotResults(labelsGT,newLabels',uvPre,uvPost,gidPre,gidPost,analysisParams);
SVMModel2.Mu = zeros(1,10);
SVMModel2.Sigma = ones(1,10);
SVMModel2.Beta = [ SVMModel.Beta(1:7);0; SVMModel.Beta(8:9)];
SVMModel2.Bias = [ SVMModel.Bias];
SVMModel = SVMModel2;
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
