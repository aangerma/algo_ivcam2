clear
close all
% Load results
resultsHeadDir = 'X:\IVCAM2_calibration _testing\crawlingResults';
resultsfiles = dir(fullfile(resultsHeadDir,'results_150_*.mat'));
% Load luts
lutCheckers = load(fullfile((resultsHeadDir),'lutCheckers.mat'));
lutFile =  fullfile((resultsHeadDir),'lutTable.csv');
metricNames = {'LDD_Temperature','gridInterDistance_errorRmsAF',...
    'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
    'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
uvMetricsId = [5,6];
gidMeticId = 2;
friendlyNames = {'Temp','GID','ScaleX','ScaleY','LUT UV RMS','LUT UV max'};
mUnits = {'deg','mm','factor','factor','pix','pix'};
data = OnlineCalibration.robotAnalysis.processSingleLut(lutFile,metricNames);
useClippedValues = 1;
itoShow = 1:150;
for k = 1:numel(resultsfiles)
    load(fullfile(resultsfiles(k).folder,resultsfiles(k).name));
    
    % Organize results
    if useClippedValues
        hFactors = [results(1).dbgRerun.acDataIn.hFactor,[results.hFactor]];
        vFactors = [results(1).dbgRerun.acDataIn.vFactor,[results.vFactor]];
    else
        hFactors = [results(1).dbgRerun.acDataIn.hFactor,getFields(results,'dbgRerun','acDataOutPreClipping','hFactor')];
        vFactors = [results(1).dbgRerun.acDataIn.vFactor,getFields(results,'dbgRerun','acDataOutPreClipping','vFactor')];
    end
    validity = [1,[results.valid]];
    
    
    figure(1);
    subplot(2,4,1);
    for metrixIdx=2:length(data.metrics)
        intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(metrixIdx).values');
        metricVisualization(metrixIdx).name = friendlyNames{metrixIdx};
        metricVisualization(metrixIdx).post = intrp(hFactors,vFactors);
        metricVisualization(metrixIdx).units = mUnits{metrixIdx};

        subplot(2,4,metrixIdx-1);
        hold on;
        plot(metricVisualization(metrixIdx).post(itoShow));
        title(metricVisualization(metrixIdx).name);
        ylabel(metricVisualization(metrixIdx).units);
        xlabel('Scene');
        grid on;
    end
    subplot(2,4,6);
    hold on;
    plot(hFactors(itoShow));
    title('hFactors');
    xlabel('Scene');
    grid on;
    subplot(2,4,7);
    hold on;
    plot(vFactors(itoShow));
    title('vFactors');
    xlabel('Scene');
    grid on;
    
end








figure(2);

hFactors = [results(1).dbgRerun.acDataIn.hFactor,[results.hFactor]];
vFactors = [results(1).dbgRerun.acDataIn.vFactor,[results.vFactor]];

hFactorsRaw = [results(1).dbgRerun.acDataIn.hFactor,getFields(results,'dbgRerun','acDataOutPreClipping','hFactor')];
vFactorsRaw = [results(1).dbgRerun.acDataIn.vFactor,getFields(results,'dbgRerun','acDataOutPreClipping','vFactor')];
validity = [1,[results.valid]];

for i = 2:numel(validity)
   if ~validity(i)
       hFactorsRaw(i) = hFactorsRaw(i-1);
       vFactorsRaw(i) = vFactorsRaw(i-1);
   end
end

subplot(1,2,1);
plot(hFactorsRaw);
hold on;
plot(hFactors);
title('hFactors (pre/post clipping)');
xlabel('Scene');
grid minor;
legend({'Pre Clipping';'Post Clipping'})

subplot(1,2,2);
plot(vFactorsRaw);
hold on;
plot(vFactors);
title('vFactors (pre/post clipping)');
xlabel('Scene');
grid minor;
legend({'Pre Clipping';'Post Clipping'})

linkaxes
