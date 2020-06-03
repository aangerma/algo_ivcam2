function [] = analyzeRollingResultsWithTM(baseDir,outPath)
    
    %definitions of required paths
    lutDataPath = fullfile(baseDir,'init');
    lutFile =  fullfile(baseDir,'init_lutTable.csv');
    resultFile = fullfile(baseDir,'results.csv');
    
    %required metrics
    metricNames = {'gridInterDistance_errorRmsAF',...
        'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
        'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
    friendlyNames = {'GID','ScaleX','ScaleY','LUT UV RMS','LUT UV max','H Factor', 'V Factor','UV RMS','UV max'};
    mUnits = {'mm','factor','factor','pix','pix','factor','factor','pix','pix'};
    plotPos =[1 2 3 5 6 4 7 8 9];
    uvMetics = {'UV RMS','UV max'};

    %get the test data and results
    data = OnlineCalibration.robotAnalysis.processSingleLut(lutFile,metricNames);
    lutCheckers = OnlineCalibration.robotAnalysis.findLutCheckerPoints(lutDataPath);
    [resNum,resTxt] = xlsread(resultFile);
    
    %build interpolation from the lut
    for metrixIdx=1:length(data.metrics)
        metricData(metrixIdx).name = friendlyNames{metrixIdx};
        metricData(metrixIdx).units = mUnits{metrixIdx};
        metricData(metrixIdx).intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(metrixIdx).values');
    end
    for metrixIdx=length(data.metrics)+1:length(friendlyNames)
        metricData(metrixIdx).name = friendlyNames{metrixIdx};
        metricData(metrixIdx).units = mUnits{metrixIdx};
    end
    %add the factors for easy reuse of code
    metricData(find(strcmp(friendlyNames,'H Factor'))).intrp = @(x,y)(x);
    metricData(find(strcmp(friendlyNames,'V Factor'))).intrp = @(x,y)(y);
    lastMetricIdx = find(strcmp(friendlyNames,'UV RMS'))-1;
    
    %get the column indexes from the result file
    iterIdx =  find( strcmp(resTxt(1,:),'iteration'));
    snIdx = find( strcmp(resTxt(1,:),'sn'));
    hFactorIdx = find( strcmp(resTxt(1,:),'hFactor'));
    vFactorIdx = find( strcmp(resTxt(1,:),'vFactor'));
    hModIdx = find( strcmp(resTxt(1,:),'hDistortion'));
    vModIdx = find( strcmp(resTxt(1,:),'vDistortion'));
    statusIdx = find( strcmp(resTxt(1,:),'status'));
    
    %seperate per unit and test according to iteration
    tests =  dirFolders(baseDir,'*_hScale*',0);
    if isempty(tests)
        tests = {[]};
    end
    uID = resTxt{2,snIdx};
    [~,testName] = fileparts(baseDir);
    fig = figure();
    maximizeFig(fig);
    
    %plot each test
    for tid=1:length(tests)
        iterMats = dirFiles(fullfile(baseDir,tests{tid}),'*_data.mat',0);
       
        iterData = load(fullfile(baseDir,tests{tid},'1_data.mat'));
        
        %first input
        hFactors = iterData.dbg.acDataIn.hFactor;
        vFactors = iterData.dbg.acDataIn.vFactor;
        validity = 1;
        uvPre = [];
        uvPost = [];
        for i=1:length(iterMats)
            iterData = load(fullfile(baseDir,tests{tid},sprintf('%d_data.mat',i)));
            hFactors(i+1) = iterData.dbg.acDataOut.hFactor;
            vFactors(i+1) = iterData.dbg.acDataOut.vFactor;
            validity(i+1) = iterData.validParams;

            calMod.hfactor = iterData.dbg.acDataIn.hFactor;
            calMod.vfactor = iterData.dbg.acDataIn.vFactor;
            calMod.Krgb = iterData.params.Krgb;
            calMod.Rrgb = iterData.params.Rrgb;
            calMod.Trgb = iterData.params.Trgb;
            calMod.rgbRes = iterData.params.rgbRes;
            calMod.rgbDistort = iterData.params.rgbDistort;
            
            calRes.Krgb = iterData.newParams.Krgb;
            calRes.Rrgb = iterData.newParams.Rrgb;
            calRes.Trgb = iterData.newParams.Trgb;
            calRes.rgbRes = iterData.newParams.rgbRes;
            calRes.rgbDistort = iterData.newParams.rgbDistort;
            calRes.hfactor = iterData.dbg.acDataOut.hFactor;
            calRes.vfactor = iterData.dbg.acDataOut.vFactor;
            
            uvPre(:,i) = OnlineCalibration.robotAnalysis.calcUvMapError(...
                lutCheckers,calMod.hfactor,calMod.vfactor,calMod);
            uvPost(:,i) = OnlineCalibration.robotAnalysis.calcUvMapError(...
                lutCheckers,calRes.hfactor,calRes.vfactor,calRes);
        end
        
        for metrixIdx=1:lastMetricIdx
            metricResults = metricData(metrixIdx).intrp(hFactors,vFactors);
            metricResults(~validity) = NaN;
            metricResults = fillmissing(metricResults,'previous');
            subplot(3,3,plotPos(metrixIdx));
            hold on;
            plot(metricResults);
            title(metricData(metrixIdx).name);
            ylabel(metricData(metrixIdx).units);
            xlabel('Iteration');
            grid on;
        end
        for mid=1:length(uvMetics)
            metrixIdx = find(strcmp(friendlyNames,uvMetics{mid}));
            metricResults = [uvPre(1,mid) uvPost(mid,:)];
            metricResults(~validity) = NaN;
            metricResults = fillmissing(metricResults,'previous');
            subplot(3,3,plotPos(metrixIdx));
            hold on;
            plot(metricResults);
            title(metricData(metrixIdx).name);
            ylabel(metricData(metrixIdx).units);
            xlabel('Iteration');
            grid on;
        end

    end
    %legend(tests);
    %if required, save figure
    if exist('outPath','var')
        mkdirSafe(outPath)
        saveas(fig,fullfile(outPath,sprintf('%s_%s_ResultPerIteration.png',uID,testName)));
    end
end