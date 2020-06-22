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
    spArr = [3 3];
    %get the test data and results
    try
        data = OnlineCalibration.robotAnalysis.processSingleLut(lutFile,metricNames);
    catch ex
        fprintf(2,'can''t find LUT data,continue without it\n');
        data.metrics = [];
        friendlyNames = friendlyNames(length(metricNames)+1:end);
        mUnits = mUnits(length(metricNames)+1:end);
        spArr = [2 2];
        plotPos =  1:prod(spArr);
        
    end
    try
        lutCheckers = OnlineCalibration.robotAnalysis.findLutCheckerPoints(lutDataPath);
    catch ex
        fprintf(2,'can''t parse lut checkers image data,continue without it\n');
    end
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
    tests =  dirFolders(baseDir,'*hScale*',0);
    if exist(fullfile(baseDir,'rolling'),'dir')
        tests{end+1} = 'rolling';
    end
    if exist(fullfile(baseDir,'checker'),'dir')
        tests{end+1} = 'checker';
    end
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
        [~, sidx] = sort(cellfun(@(x) sscanf(x,'%d_data.mat'),iterMats));
        iterMats = iterMats(sidx);
        iterData = load(fullfile(baseDir,tests{tid},iterMats{1}));
        
        %first input
        hFactors = iterData.dbg.acDataIn.hFactor;
        vFactors = iterData.dbg.acDataIn.vFactor;
        validity = 1;
        uvPre = [];
        uvPost = [];
        lastCalRes = [];
        lastAcData = [];
        for i=1:length(iterMats)
            iterData = load(fullfile(baseDir,tests{tid},iterMats{i}));
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
            if exist('lutCheckers','var')
            uvPre(:,i) = OnlineCalibration.robotAnalysis.calcUvMapError(...
                lutCheckers,calMod.hfactor,calMod.vfactor,calMod);
            uvPost(:,i) = OnlineCalibration.robotAnalysis.calcUvMapError(...
                lutCheckers,calRes.hfactor,calRes.vfactor,calRes);
            else
              uvPre(1:4,i) = NaN;  
              uvPost(1:4,i) = NaN;  
            end
            if i==1
                lastCalRes = calMod;
                lastAcData = iterData.dbg.acDataIn;
            end
            if  validity(i+1)
                lastCalRes = calRes;
                lastAcData = iterData.dbg.acDataOut;
            end
        end
        
        for metrixIdx=1:lastMetricIdx
            metricResults = metricData(metrixIdx).intrp(hFactors,vFactors);
            metricResults(~validity) = NaN;
            metricResults = fillmissing(metricResults,'previous');
            subplot(spArr(1),spArr(2),plotPos(metrixIdx));
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
            subplot(spArr(1),spArr(2),plotPos(metrixIdx));
            hold on;
            plot(metricResults);
            title(metricData(metrixIdx).name);
            ylabel(metricData(metrixIdx).units);
            xlabel('Iteration');
            grid on;
        end
        %generate UV table
        if ~isempty(lastAcData)
            params.RGBImageSize =  lastCalRes.rgbRes;
            res =[];
            res.color.Kn = single(du.math.normalizeK(lastCalRes.Krgb,lastCalRes.rgbRes));
            res.color.d =  single(lastCalRes.rgbDistort);
            res.extrinsics.r = single(lastCalRes.Rrgb);
            res.extrinsics.t = single(lastCalRes.Trgb);
            RGBTable =  Calibration.rgb.buildRGBTable(res,params,40);
            flags = zeros(1,6,'uint8');
            flags(1:length(lastAcData.flags)) = lastAcData.flags;
            lastAcData.flags = flags;
            newAcDataTable = Calibration.tables.convertCalibDataToBinTable(lastAcData, 'Algo_AutoCalibration');
            
            if exist('outPath','var')
                mkdirSafe(outPath)
                writeAllBytes(RGBTable.data,[uID ' RGB_Calibration_Info_CalibInfo_Ver_00_48.bin']);
                writeAllBytes(newAcDataTable,[uID ' Algo_AutoCalibration_CalibInfo_Ver_01_00']);
            end
            %lastValidMat =  iterMats{find(validity(2:end),1,'last')};
            %[newAcDataTable1, RGBTable1 ] = OnlineCalibration.robotAnalysis.tablesFromDataMat(fullfile(baseDir,tests{tid},lastValidMat),[]);
        else
            fprintf(2,'no successfull AC iteration\n');
        end

    end
    %legend(tests);
    %if required, save figure
    if exist('outPath','var')
        saveas(fig,fullfile(outPath,sprintf('%s_%s_ResultPerIteration.png',uID,testName)));
    end
end