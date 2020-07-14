clear;
svmModelPath = 'X:\IVCAM2_calibration _testing\analysisResults\20_May_17___03_02_AC2_Iterative_Status\SVMModelLinear.mat';
load(svmModelPath);
pred = @(x,SVM) (x-SVM.Mu)./SVM.Sigma*SVM.Beta+SVM.Bias > 0;

envTrain = load('X:\IVCAM2_calibration _testing\analysisResults\20_May_24___15_06_AC2_status_test\results.mat');
envTest1 = load('env.mat');
envTest2 = load('envNew.mat');
results = envTrain.results;
% Classifiy scenes
analysisParams.successFunc = [0,2;...
                              1,2;...
                              3,3;...
                              5,4;...
                              7,4;...
                              9,5;...
                              12,6;...
                              100,6];

gidPre = [results.gidPre];
uvPre = [results.uvErrPre];
for k = 1:numel(results)
    gidPost(k) = results(k).gidPostK2DSM(end);
    uvPost(k) = results(k).uvErrPostK2DSM(end);
end
labelsUVGT = OnlineCalibration.datasetAnalysis.succesfulOptimization(uvPre,uvPost,analysisParams.successFunc)';
gidImproved = gidPost<gidPre;
featuresMat = OnlineCalibration.aux.extractFeatures(getFields(results,'desicionParams'),[]);
figure(1);
subplot(131);
cm = confusionchart(gidImproved,pred(featuresMat,SVMModel));
subplot(132);
cm = confusionchart(envTest1.gidImproved,pred(envTest1.featuresMat,SVMModel));
subplot(133);
cm = confusionchart(envTest2.gidImproved,pred(envTest2.featuresMat,SVMModel));


%% Train SVM - For all params or just one
featuresMat = OnlineCalibration.aux.extractFeatures(getFields(results,'desicionParams'),[]);
labelsGT = gidImproved;
labelsGT(any(isnan(featuresMat),2)) = [];
labelsUV = labelsUVGT;
labelsUV(any(isnan(featuresMat),2)) = [];
gidImprovedTrain = gidImproved;
gidImprovedTrain(any(isnan(featuresMat),2)) = [];
featuresMat(any(isnan(featuresMat),2),:) = [];


% featuresMat(:,1) = 0;
% featuresMat(:,8) = 0;
% featuresMat(:,6) = featuresMat(:,6)-featuresMat(:,5);
% featuresMat(:,10) = 0;
featur = featuresMat;
svmTrain = @(feature,label) fitcsvm(feature,label,'KernelFunction','linear',...
    'Standardize',false);
SVMModel = svmTrain(featur,labelsGT);
SVMModel2.Mu = zeros(1,10);
SVMModel2.Sigma = ones(1,10);
SVMModel2.Beta = SVMModel.Beta;
SVMModel2.Bias = SVMModel.Bias;

figure(5);
for db = SVMModel2.Bias:0.2:SVMModel2.Bias+5
SVMModel = SVMModel2;
SVMModel.Bias = db;
tabplot;
subplot(131);
cm = confusionchart(labelsGT,pred(featuresMat,SVMModel));
subplot(132);
cm = confusionchart(envTest1.gidImproved,pred(envTest1.featuresMat,SVMModel));
subplot(133);
cm = confusionchart(envTest2.gidImproved,pred(envTest2.featuresMat,SVMModel));

end


load(svmModelPath);
SVMModel.Bias = SVMModel.Bias+1.2;
figure;
subplot(131);
cm = confusionchart(labelsGT,pred(featuresMat,SVMModel));
subplot(132);
cm = confusionchart(envTest1.gidImproved,pred(envTest1.featuresMat,SVMModel));
subplot(133);
cm = confusionchart(envTest2.gidImproved,pred(envTest2.featuresMat,SVMModel));
