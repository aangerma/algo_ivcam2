function [] = analyzeRollingResults(baseDir,outPath)
    
    %definitions of required paths
    lutDataPath = fullfile(baseDir,'init');
    lutFile =  fullfile(baseDir,'init_lutTable.csv');
    resultFile = fullfile(baseDir,'results.csv');
    
    %required metrics
    metricNames = {'gridInterDistance_errorRmsAF',...
        'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
        'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
    friendlyNames = {'GID','ScaleX','ScaleY','LUT UV RMS','LUT UV max','H Factor', 'V Factor'};
    mUnits = {'mm','factor','factor','pix','pix','factor','factor'};
    
    %get the test data and results
    data = OnlineCalibration.robotAnalysis.processSingleLut(lutFile,metricNames);
    %lutCheckers = OnlineCalibration.robotAnalysis.findLutCheckerPoints(lutDataPath);
    [resNum,resTxt] = xlsread(resultFile);

    %build interpolation from the lut
    for metrixIdx=1:length(data.metrics)
        metricData(metrixIdx).name = friendlyNames{metrixIdx};
        metricData(metrixIdx).units = mUnits{metrixIdx};
        metricData(metrixIdx).intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(metrixIdx).values');
    end
    %add the factors for easy reuse of code
    metrixIdx = metrixIdx + 1;
    metricData(metrixIdx).name = friendlyNames{metrixIdx};
    metricData(metrixIdx).units = mUnits{metrixIdx};
    metricData(metrixIdx).intrp = @(x,y)(x);
    
    metrixIdx = metrixIdx + 1;
    metricData(metrixIdx).name = friendlyNames{metrixIdx};
    metricData(metrixIdx).units = mUnits{metrixIdx};
    metricData(metrixIdx).intrp = @(x,y)(y);
    
    %get the column indexes from the result file 
    iterIdx =  find( strcmp(resTxt(1,:),'iteration'));
    snIdx = find( strcmp(resTxt(1,:),'sn'));
    hFactorIdx = find( strcmp(resTxt(1,:),'hFactor'));
    vFactorIdx = find( strcmp(resTxt(1,:),'vFactor'));
    hModIdx = find( strcmp(resTxt(1,:),'hDistortion'));
    vModIdx = find( strcmp(resTxt(1,:),'vDistortion'));
    statusIdx = find( strcmp(resTxt(1,:),'status'));
    
    %seperate per unit and test according to iteration
    uID = resTxt{2,snIdx};
    [~,testName] = fileparts(baseDir);
    iters = find(diff(resNum(:,iterIdx))<0);
    iters(end+1) = size(resNum,1);
    startIdx = 1;
    fig = figure();
    maximizeFig(fig);
    
    %plot each test
    for i=1:length(iters)
        idxs = startIdx:iters(i);
        startIdx = iters(i)+1;
        hFactors = [resNum(idxs(1),hModIdx); resNum(idxs,hFactorIdx)];
        vFactors = [resNum(idxs(1),vModIdx); resNum(idxs,vFactorIdx)];
        validity = [1; resNum(idxs,statusIdx)];
        for metrixIdx=1:length(metricData)
            metricResults = metricData(metrixIdx).intrp(hFactors,vFactors);
            metricResults(~validity) = NaN;
            metricResults = fillmissing(metricResults,'previous');
            subplot(2,4,metrixIdx);
            hold on;
            plot(metricResults);
            title(metricData(metrixIdx).name);
            ylabel(metricData(metrixIdx).units);
            xlabel('Iteration');
            grid on;
        end
    end
    
    %if required, save figure
    if exist('outPath','var')
        mkdirSafe(outPath)
        saveas(fig,fullfile(outPath,sprintf('%s_%s_ResultPerIteration.png',uID,testName)));
    end
end