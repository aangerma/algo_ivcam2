function [valPassed, valResults] = validateCalibration(runParams,calibParams,fprintff,spark)
    
    if(~exist('spark','var'))
        spark=[];
    end
    write2spark = ~isempty(spark);
    valPassed = false;
    valResults = [];
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
        debugMode = flip(dec2bin(uint16(calibParams.validationConfig.debugMode),2)=='1');
        if any(debugMode)
            mkdirSafe(outFolder);
        end
        
        %run all metrics
        enabledMetrics = fieldnames(calibParams.validationConfig);
        for i=1:length(enabledMetrics)
            switch enabledMetrics{i}
                case 'sharpness'
                    sharpConfig = calibParams.validationConfig.sharpness;
                    frames = hw.getFrame(sharpConfig.numOfFrames,0);
                    [~, sharpRes] = Validation.metrics.gridEdgeSharp(frames, []);
                    valResults.horizontalSharpness = sharpRes.horizMean;
                    valResults.verticalSharpness = sharpRes.vertMean;
                    saveValidationData(sharpRes,frames,enabledMetrics{i},outFolder,debugMode);
                case 'temporalNoise'
                    tempNConfig = calibParams.validationConfig.temporalNoise;
                    frames = hw.getFrame(tempNConfig.numOfFrames,0);
                    params = Validation.aux.defaultMetricsParams();
                    params.roi = tempNConfig.roi;
                    [tns,tnsResults] = Validation.metrics.zStd(frames, params);
                    valResults.temporalNoise = tns;
                    saveValidationData(tnsResults,frames,enabledMetrics{i},outFolder,debugMode);
                case 'delays'
                    [delayRes,frames] = Calibration.validation.validateDelays(hw,calibParams,fprintff);
                    valResults = Validation.aux.mergeResultStruct(valResults, delayRes);
                    saveValidationData([],frames,enabledMetrics{i},outFolder,debugMode);
                case 'dfz'
                    dfzConfig = calibParams.validationConfig.temporalNoise;
                    frames = hw.getFrame(dfzConfig.numOfFrames);
                    dfzRes = Calibration.validation.validateDFZ(hw,frames,fprintff);
                    valResults = Validation.aux.mergeResultStruct(valResults, dfzRes);
                    saveValidationData([],frames,enabledMetrics{i},outFolder,debugMode);
                case 'roi'
                    [roiRes, frames,dbg] = Calibration.validation.validateROI(hw,calibParams,fprintff);
                    valResults = Validation.aux.mergeResultStruct(valResults, roiRes);
                    saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
                case 'los'
                    losConfig = calibParams.validationConfig.los;
                    [losRes,~,frames,dbg] = Calibration.validation.validateLOS(hw,runParams,losConfig,fprintff);
                    valResults = Validation.aux.mergeResultStruct(valResults, losRes);
                    saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
                case 'dsm'
                    [dsmRes, dbg] = Calibration.validation.validateDSM(hw,fprintff);
                    valResults = Validation.aux.mergeResultStruct(valResults, dsmRes);
                    saveValidationData(dbg,[],enabledMetrics{i},outFolder,debugMode);
            end
        end
               
        Calibration.aux.logResults(valResults,runParams,'validationResults.txt');
        Calibration.aux.writeResults2Spark(valResults,spark,calibParams.validationErrRange,write2spark);
        valPassed = Calibration.aux.mergeScores(valResults,calibParams.validationErrRange,fprintff,1);
        
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