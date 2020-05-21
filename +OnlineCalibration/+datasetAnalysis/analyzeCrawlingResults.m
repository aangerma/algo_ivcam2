clear
close all
% Load results
resultsHeadDir = 'X:\IVCAM2_calibration _testing\crawlingResults\hScale_0.98_vScale_0.98';
load(fullfile(resultsHeadDir,'results.mat'));

% Load luts
lutCheckers = load(fullfile(fileparts(resultsHeadDir),'lutCheckers.mat'));
lutFile =  fullfile(fileparts(resultsHeadDir),'lutTable.csv');

metricNames = {'LDD_Temperature','gridInterDistance_errorRmsAF',...
    'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
    'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
uvMetricsId = [5,6];
gidMeticId = 2;
friendlyNames = {'Temp','GID','ScaleX','ScaleY','LUT UV RMS','LUT UV max'};
mUnits = {'deg','mm','factor','factor','pix','pix'};
data = OnlineCalibration.robotAnalysis.processSingleLut(lutFile,metricNames);

% Organize results
hFactors = [results(1).dbgRerun.acDataIn.hFactor,[results.hFactor]];
vFactors = [results(1).dbgRerun.acDataIn.vFactor,[results.vFactor]];
validity = [1,[results.valid]];


figure;
subplot(2,3,1);
for metrixIdx=1:length(data.metrics)
    intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(metrixIdx).values');
    metricVisualization(metrixIdx).name = friendlyNames{metrixIdx};
    metricVisualization(metrixIdx).post = intrp(hFactors,vFactors);
    metricVisualization(metrixIdx).units = mUnits{metrixIdx};
    
    subplot(2,3,metrixIdx);
    plot(metricVisualization(metrixIdx).post);
    title(metricVisualization(metrixIdx).name);
    ylabel(metricVisualization(metrixIdx).units);
    xlabel('Scene');
    grid minor;
end

