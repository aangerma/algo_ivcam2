function [valPassed, valResults] = validateCalibration(runParams,calibParams,fprintff,spark)
    
    if(~exist('spark','var'))
        spark=[];
    end
    write2spark = ~isempty(spark);
    valPassed = false;
    defaultDebug = 0;
    valResults = [];
    allResults = [];
    if runParams.validation
        % open stream and capture image of the validation target
        fprintff('[-] Validation...\n');
        hw = HWinterface();
        hw.getFrame;
        fprintff('opening stream...');
        frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
        
        ff = Calibration.aux.invisibleFigure();
        subplot(1,3,1); imagesc(frame.i); title('Validation I');
        subplot(1,3,2); imagesc(frame.z/8); title('Validation Z');
        subplot(1,3,3); imagesc(frame.c); title('Validation C');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Frame');
        
        r=Calibration.RegState(hw);
        r.add('JFILbypass$'        ,true    );
        r.add('DIGGgammaScale', uint16([256,256]));
        r.set();
        pause(0.1);
        
        scanLinesFrame = hw.getFrame();
        ff = Calibration.aux.invisibleFigure();
        imagesc(scanLinesFrame.i); title('Validation Scan Lines Frame');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','scanLinesFrame');
        
        r.reset();
        hw.cmd('mwd a0020a6c a0020a70 04000400 // DIGGgammaScale'); % Todo - fix regstate to read gammascale correctly
        hw.shadowUpdate;
        fprintff('Done.\n');
        
        
        outFolder = fullfile(runParams.outputFolder,'Validation',[]);
        mkdirSafe(outFolder);
        debugMode = flip(dec2bin(uint16(defaultDebug),2)=='1');
        
        
        %run all metrics
        enabledMetrics = fieldnames(calibParams.validationConfig);
        for i=1:length(enabledMetrics)
            if strfind(enabledMetrics{i},'debugMode')
                 debugMode = flip(dec2bin(uint16(calibParams.validationConfig.(enabledMetrics{i})),2)=='1');
                 fprintff('Changeing debug mode to %d.\n',calibParams.validationConfig.(enabledMetrics{i}));
            elseif  strfind(enabledMetrics{i},'sharpness')
                sharpConfig = calibParams.validationConfig.(enabledMetrics{i});
                frames = hw.getFrame(sharpConfig.numOfFrames,0);
                [~, allSharpRes,dbg] = Validation.metrics.gridEdgeSharp(frames, []);
                sharpRes.horizontalSharpness = allSharpRes.horizMean;
                sharpRes.verticalSharpness = allSharpRes.vertMean;
                valResults = Validation.aux.mergeResultStruct(valResults, sharpRes);
                saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = allSharpRes;
            elseif strfind(enabledMetrics{i},'temporalNoise')
                tempNConfig = calibParams.validationConfig.(enabledMetrics{i});
                frames = hw.getFrame(tempNConfig.numOfFrames,0);
                params = Validation.aux.defaultMetricsParams();
                params.enabledMetrics{i} = tempNConfig.roi;
                [tns,allTnsResults] = Validation.metrics.zStd(frames, params);
                tnsRes.temporalNoise = tns;
                valResults = Validation.aux.mergeResultStruct(valResults, tnsRes);
                saveValidationData(allTnsResults,frames,enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = allTnsResults;
            elseif strfind(enabledMetrics{i},'delays')
                [delayRes,frames] = Calibration.validation.validateDelays(hw,calibParams,fprintff);
                valResults = Validation.aux.mergeResultStruct(valResults, delayRes);
                saveValidationData([],frames,enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = delayRes;
            elseif strfind(enabledMetrics{i},'dfz')
                dfzConfig = calibParams.validationConfig.(enabledMetrics{i});
                frames = hw.getFrame(dfzConfig.numOfFrames);
                [dfzRes,allDfzRes] = Calibration.validation.validateDFZ(hw,frames,fprintff);
                valResults = Validation.aux.mergeResultStruct(valResults, dfzRes);
                saveValidationData([],frames,enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = allDfzRes;
            elseif strfind(enabledMetrics{i},'roi')
                [roiRes, frames,dbg] = Calibration.validation.validateROI(hw,calibParams,fprintff);
                valResults = Validation.aux.mergeResultStruct(valResults, roiRes);
                saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = roiRes;
            elseif strfind(enabledMetrics{i},'los')
                losConfig = calibParams.validationConfig.(enabledMetrics{i});
                [losRes,allLosResults,frames,dbg] = Calibration.validation.validateLOS(hw,runParams,losConfig,fprintff);
                valResults = Validation.aux.mergeResultStruct(valResults, losRes);
                saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = allLosResults;
            elseif strfind(enabledMetrics{i},'dsm')
                [dsmRes, dbg] = Calibration.validation.validateDSM(hw,fprintff);
                valResults = Validation.aux.mergeResultStruct(valResults, dsmRes);
                saveValidationData(dbg,[],enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = dsmRes;
            elseif strfind(enabledMetrics{i},'coverage')
                covConfig = calibParams.validationConfig.(enabledMetrics{i});
                [covScore,allCovRes, dbg,frames] = Calibration.validation.validateCoverage(hw,covConfig.sphericalMode,covConfig.numOfFrames);
                covRes.irCoverage = covScore;
                fprintff('ir Coverage:  %2.2g\n',covScore);
                valResults = Validation.aux.mergeResultStruct(valResults, covRes);
                saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
                allResults.Validation.(enabledMetrics{i}) = allCovRes;
            elseif strfind(enabledMetrics{i},'wait')
                 waitConfig = calibParams.validationConfig.(enabledMetrics{i});
                 fprintff('waiting for %d seconds...',waitConfig.timeoutSec);
                 pause(waitConfig.timeoutSec);
                 fprintff('Done.\n');
            end
        end
        
        Calibration.aux.logResults(valResults,runParams,'validationResults.txt');
        Calibration.aux.writeResults2Spark(valResults,spark,calibParams.validationErrRange,write2spark);
        valPassed = Calibration.aux.mergeScores(valResults,calibParams.validationErrRange,fprintff,1);
        struct2xml_(allResults,fullfile(outFolder,'fullReport.xml'));
        Calibration.aux.logResults(allResults,runParams,'fullValidationReport.txt');
        %{
        fprintff('%s: %2.2gmm\n','zSTD',zSTD);
        fprintff('%s: %2.2g\n','horizSharpnessMean',results.horizMean);
        fprintff('%s: %2.2g\n','vertSharpnessMean',results.vertMean);
       
        fprintff('Validation finished.\n');
        %}
    end
    
end
function saveValidationData(debugData,frames,metric,outFolder,debugMode)
    
    % debug mode 1 indicates if we store the debug data of the metric
    if debugMode(1) && ~isempty(debugData)
        save(fullfile(outFolder,[metric '.mat']),'debugData');
    end
    
    % debug mode 2 indicates if we store the frames data of the metric
    if debugMode(2) && ~isempty(frames)
        f = fieldnames(frames);
        for i = 1:length(f)
            imfn = fullfile(dirname,strcat(metric,'Frame_',f{i},'.png'));
            imwrite(frames.(f{i}),imfn);
        end
    end
    
end