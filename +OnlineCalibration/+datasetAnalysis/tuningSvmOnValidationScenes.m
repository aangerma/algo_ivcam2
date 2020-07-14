clear
close all
valDirs = {'W:\testResults\05201048\**';...
           'W:\testResults\05251000\**';...
           'W:\testResults\05251739\**';...
           'W:\testResults\05252120\**';...
           'W:\testResults\05260830\**';...
            };
lutsPaths = {'W:\testResults\05201048\lutTable - Copy.csv';...
             'W:\testResults\05251000\init_lutTable.csv';...
             'W:\testResults\05251739\init_lutTable.csv';...
             'W:\testResults\05252120\init_lutTable.csv';...
             'W:\testResults\05260830\init_lutTable.csv';...
             };

metricNames = {'LDD_Temperature','gridInterDistance_errorRmsAF',...
    'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
    'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};

uvMetricsId = [5,6];
gidMeticId = 2;
friendlyNames = {'Temp','GID','ScaleX','ScaleY','LUT UV RMS','LUT UV max'};
mUnits = {'deg','mm','factor','factor','pix','pix'};


%% For each one, load features and try different SVM models
scI = 1;
for i = 4%1:numel(valDirs)
   dataFiles = dir(fullfile(valDirs{i},'*_dbg.mat'));
   if isempty(dataFiles)
       dataFiles = dir(fullfile(valDirs{i},'*_data.mat'));
       
   end
   data = OnlineCalibration.robotAnalysis.processSingleLut(lutsPaths{i},metricNames);
   intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(gidMeticId).values');

   
   for d = 1:numel(dataFiles)
       fprintf('%d/%d\n',d,numel(dataFiles))
       dataFn = fullfile(dataFiles(d).folder,dataFiles(d).name); 
       load(dataFn);
       params.svmModelPath = fullfile('C:\source\algo_ivcam2\+OnlineCalibration','+SVMModel','SVMModelLinear.mat');
       validFixBySVM(scI,1) = OnlineCalibration.aux.validBySVM(dbg.decisionParams,params);
       params.svmModelPath = fullfile('C:\otherSource\algo_ivcam2\+OnlineCalibration','+SVMModel','SVMModelLinear.mat');
       validFixBySVM(scI,2) = OnlineCalibration.aux.validBySVM(dbg.decisionParams,params);
%        params.svmModelPath = fullfile('C:\source\algo_ivcam2\SVMModelLinear.mat');
%        validFixBySVM(scI,3) = OnlineCalibration.aux.validBySVM(dbg.decisionParams,params);
       featuresMat(scI,:) = OnlineCalibration.aux.extractFeatures(dbg.decisionParams);

       
       pre = intrp(dbg.acDataIn.hFactor,dbg.acDataIn.vFactor);
       if isfield(dbg,'acDataOutPreClipping')
           post = intrp(dbg.acDataOutPreClipping.hFactor,dbg.acDataOutPreClipping.vFactor);
       else
           post = intrp(dbg.acDataOut.hFactor,dbg.acDataOut.vFactor);
       end

       gidImproved(scI) = post<pre;
       scI = scI + 1;
       dbg.validFixBySVM
   end
end
%% Produce Confusion matrix  - Good means improvement in gid
figure;
cm = confusionchart(gidImproved,validFixBySVM(:,1));
figure;
cm = confusionchart(gidImproved,validFixBySVM(:,2));
% figure;
% cm = confusionchart(gidImproved,validFixBySVM(:,3));




% 'C:\source\algo_ivcam2\SVMModelLinear.mat'

% size(featuresMat)
% params.svmModelPath = 'C:\source\algo_ivcam2\SVMModelLinear.mat';
