function [valPassed, valResults] = validateCalibrationFast(runParams,calibParams,fprintff,spark,app)
    
    if(~exist('spark','var'))
        spark=[];
    end
    write2spark = ~isempty(spark);
    valPassed = false;
    defaultDebug = 0;
    valResults = [];
    allResults = [];
    
    
    outFolder = fullfile(runParams.outputFolder,'Validation',[]);
    mkdirSafe(outFolder);
    
    % open stream and capture image of the validation target
    enabledMetrics = fieldnames(calibParams.validationConfig);
    fprintff('[-] Validation...\n');
    hw = HWinterface();
    if calibParams.gnrl.dirtybitBypass
        hw.cmd('DIRTYBITBYPASS');
    end
    fprintff('opening stream...');
    
    hw.startStream(0,calibParams.gnrl.depthRes,calibParams.gnrl.rgbRes);
    hw.getFrame;
    fprintff('Done\n');
    if calibParams.gnrl.enableAllRange
        hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
        hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
        hw.shadowUpdate;
    end
    
    % Collecting hardware state
    z2mm = double(hw.z2mm);
    
    if calibParams.gnrl.wait > 0
        fprintff('waiting for %d seconds...',calibParams.gnrl.wait);
        pause(calibParams.gnrl.wait);
        fprintff('Done.\n');
    end
    
    if calibParams.gnrl.manualCapture
        %frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]), 'Please align checkerboard to screen');
        Calibration.aux.changeCameraLocation(hw, false, calibParams.validationConfig.target.type,calibParams.validationConfig.target.distance,calibParams.validationConfig.target.angle,calibParams,hw,1,diag([.6 .6 1]), 'Please align checkerboard to screen');
    end
    
    
    if calibParams.gnrl.warmUp.enable
        tic;
        lastCurrTime = 0;
        while 1 % Pressing skip will stop this process
            pause(1);
            currTime = toc;
            %     % Calculate next estimate
            if (currTime-lastCurrTime> calibParams.gnrl.warmUp.cadenceSec)
                lastCurrTime = currTime;
                [lddTmptr,~,~ ,~ ] = hw.getLddTemperature();
                fprintff(',%2.2f',lddTmptr);
                if abs(lddTmptr - lastLddTmptr) <  calibParams.gnrl.warmUp.threshold
                    fprintff(' Temperature converged (diff<%.2fdeg)\n',calibParams.gnrl.warmUp.threshold);
                    break;
                end
                
                lastLddTmptr = lddTmptr;
            end
        end
    end
    
    debugMode = flip(dec2bin(uint16(calibParams.gnrl.debugMode),2)=='1');
    fprintff('Setting debug mode to %d.\n',calibParams.gnrl.debugMode);
    
    if calibParams.gnrl.readRegState
        fprintff('Collecting registers state...');
        hw.getRegsFromUnit(fullfile(runParams.outputFolder,'validationRegState.txt') ,0 );
        fprintff('Done\n');
    end
    
    temps = [];
    temps.LddTemp = hw.getLddTemperature;
    temps.HumTemp = hw.getHumidityTemperature;
    frame =  hw.getFrame(30);
    framesDefault = hw.getFrame(100,0);
    rgbFrame  = hw.getColorFrame();
    
    % long range
    hw.setPresetControlState(1);
    hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
    hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
    hw.shadowUpdate;
    framesLongRange = hw.getFrame(100,0);
    avgFramesLongRange = averageFrame(framesLongRange);
    
    % short range
    hw.setPresetControlState(2);
    framesShortRange = hw.getFrame(100,0);
    avgFramesShortRange = averageFrame(framesShortRange);
    
    
    
    
    ff = Calibration.aux.invisibleFigure();
    subplot(1,3,1); imagesc(frame.i); title('Validation I');
    subplot(1,3,2); imagesc(frame.z/hw.z2mm); title('Validation Z');
    subplot(1,3,3); imagesc(frame.c); title('Validation C');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Frame');
    
    
    
    %run all metrics
    for i=1:length(enabledMetrics)
        if  strfind(enabledMetrics{i},'presetsCompare')
            fprintff('Starting %s Validation...',enabledMetrics{i});
            presetCompareConfig = calibParams.validationConfig.(enabledMetrics{i});
            frames=[];
            frames.LRframe=avgFramesLongRange;
            frames.SRframe=avgFramesShortRange;
            [presetCompareRes,frames] = Calibration.validation.validatePresets(hw, presetCompareConfig,runParams, fprintff,frames);
            valResults = Validation.aux.mergeResultStruct(valResults, presetCompareRes);
            saveValidationData([],frames,enabledMetrics{i},outFolder,debugMode);
            allResults.Validation.(enabledMetrics{i}) = presetCompareRes;
            fprintff('Done\n');
        elseif  strfind(enabledMetrics{i},'HVM_Val')
            fprintff('Starting %s Validation...',enabledMetrics{i});
            [valResults ,allResults] = HVM_val_1(hw,runParams,calibParams,fprintff,spark,app,valResults);
            [valResults ,allCovRes] = HVM_val_Coverage(hw,runParams,calibParams,fprintff,spark,app,valResults);
            allResults.HVM.coverage = allCovRes;
            allResults.HVM.LddTemp = hw.getLddTemperature;
            allResults.HVM.HumTemp = hw.getHumidityTemperature;
            fprintff('Done\n');
        elseif  strfind(enabledMetrics{i},'sharpness')
            fprintff('Starting %s Validation...',enabledMetrics{i});
            sharpConfig = calibParams.validationConfig.(enabledMetrics{i});
            frames = averageFrame(framesDefault(1:sharpConfig.numOfFrames));
            [~, allSharpRes,dbg] = Validation.metrics.gridEdgeSharp(frames, []);
            sharpRes.horizontalSharpness = allSharpRes.horizMean;
            sharpRes.verticalSharpness = allSharpRes.vertMean;
            valResults = Validation.aux.mergeResultStruct(valResults, sharpRes);
            saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
            allResults.Validation.(enabledMetrics{i}) = allSharpRes;
            fprintff('Done\n');
        elseif strfind(enabledMetrics{i},'temporalNoise')
            fprintff('Starting %s Validation...',enabledMetrics{i});
            tempNConfig = calibParams.validationConfig.(enabledMetrics{i});
            frames = framesDefault(1:tempNConfig.numOfFrames);
            params = Validation.aux.defaultMetricsParams();
            params.camera.zMaxSubMM = z2mm;
            params.enabledMetrics{i} = tempNConfig.roi;
            [tns,allTnsResults,zstdDbg] = Validation.metrics.zStd(frames, params);
            tnsRes.temporalNoise = tns;
            tnsRes.tempNoise95 = allTnsResults.tempNoise95;
            
            ff = Calibration.aux.invisibleFigure;
            imagesc(zstdDbg.noiseStd,[0,allTnsResults.tempNoise95]); colorbar;
            title('zSTD Map'); colorbar;
            Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',sprintf('zSTD'));
            
            
            valResults = Validation.aux.mergeResultStruct(valResults, tnsRes);
            saveValidationData(allTnsResults,frames,enabledMetrics{i},outFolder,debugMode);
            allResults.Validation.(enabledMetrics{i}) = allTnsResults;
            fprintff('Done\n');
        elseif strfind(enabledMetrics{i},'dfz')
            fprintff('Starting %s Validation...',enabledMetrics{i});
            dfzConfig = calibParams.validationConfig.(enabledMetrics{i});
            frames = averageFrame(framesDefault(1:dfzConfig.numOfFrames));
            save(fullfile(runParams.outputFolder,'postResetValCbFrame.mat'),'frames');
            [dfzRes,allDfzRes,dbg] = Calibration.validation.validateDFZ(hw,frames,fprintff,calibParams,runParams);
            valResults = Validation.aux.mergeResultStruct(valResults, dfzRes);
            saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
            allResults.Validation.(enabledMetrics{i}) = allDfzRes;
            fprintff('Done\n');
        elseif strfind(enabledMetrics{i},'rgb')
            fprintff('Starting %s Validation...',enabledMetrics{i});
            rgbConfig = calibParams.validationConfig.(enabledMetrics{i});
            depthFrame = averageFrame(framesDefault(1:rgbConfig.numOfFrames));
            [rgbRes,frames,dbg] = Calibration.validation.validateRGB(hw, calibParams,runParams, fprintff,depthFrame,rgbFrame);
            valResults = Validation.aux.mergeResultStruct(valResults, rgbRes);
            saveValidationData(dbg,frames,enabledMetrics{i},outFolder,debugMode);
            allResults.Validation.(enabledMetrics{i}) = rgbRes;
            fprintff('Done\n');
        end
    end
    Calibration.aux.writeResults2Spark(valResults,spark,calibParams.validationErrRange,write2spark,'Val');
    Calibration.aux.logResults(valResults,runParams,'validationResults.txt');
    
    valPassed = Calibration.aux.mergeScores(valResults,calibParams.validationErrRange,fprintff,1);
    val.res = allResults.Validation;
    val.res.temps = temps;
    if isfield(allResults,'HVM')
        hvm.res = allResults.HVM;
        struct2xml_(hvm,fullfile(outFolder,'HVMReport.xml'));
    else
        hvm.res = [];
    end
    
    struct2xml_(val,fullfile(outFolder,'ValReport.xml'));
    %        struct2xml_(allResults,fullfile(outFolder,'fullReport.xml'));
    Calibration.aux.logResults(allResults,runParams,'fullValidationReport.txt');
    %{
        fprintff('%s: %2.2gmm\n','zSTD',zSTD);
        fprintff('%s: %2.2g\n','horizSharpnessMean',results.horizMean);
        fprintff('%s: %2.2g\n','vertSharpnessMean',results.vertMean);
       
        fprintff('Validation finished.\n');
    %}
    
    
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

function [valResults ,allResults] = HVM_val_1(hw,runParams,calibParams,fprintff,spark,app,valResults)
    % function : perform the DFZ, Sharpness, temporalNoise, roi
    %           capturing 100 frames
    %           reading K matrix and zMaxSubMM
    % 		DFZ  (default configuration)
    % 			100 frames average
    % 			params.camera.K = getKMat(hw);
    % 			params.camera.zMaxSubMM = 2^double(hw.read('GNRLzMaxSubMMExp'));
    %
    % 		sharpness (default configuration)
    % 			100 frames not average
    %
    % 		temporalNoise (default configuration)
    % 			100 frames not average
    %
    % 		ROI (default configuration)
    %       LOS (default configuration)
    %
    %% capturing
    nof_frames = calibParams.validationConfig.HVM_Val.numOfFrames;
    frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZI', nof_frames);
    
    %% get K zMaxSubMM
    params.camera.K          = getKMat(hw);
    params.camera.zMaxSubMM  = 2^double(hw.read('GNRLzMaxSubMMExp'));
    sz = hw.streamSize();
    [valResults ,allResults] = HVM_Val_Calc(frameBytes,sz,params,calibParams,valResults);
    
end
function [valResults ,allResults] = HVM_val_Coverage(hw,runParams,calibParams,fprintff,spark,app,valResults)
    % function : perform the DFZ, Sharpness, temporalNoise, roi
    %           capturing 100 frames
    % 		coverage (default configuration 'JFILBypass$' = true;
    % 			100 frames not average
    % 		ROI (default configuration)
    %       LOS (default configuration)
    %% pre-capturing setting
    r = Calibration.RegState(hw);
    xgaRes = [768,1024];
    if ~all(calibParams.gnrl.depthRes == xgaRes)
        r.add('JFILBypass$',true);
    end
    r.set();
    pause(0.1);
    %% capturing
    nof_frames = calibParams.validationConfig.coverage.numOfFrames;
    frameBytes = Calibration.aux.captureFramesWrapper(hw, 'I', nof_frames);
    sz = hw.streamSize();
    
    %calculate ir coverage metric
    [valResults ,allResults] = HVM_Val_Coverage_Calc(frameBytes,sz,calibParams,valResults);
    %clean up hw
    r.reset();
end

function K = getKMat(hw)
    CBUFspare = typecast(hw.read('CBUFspare'),'single');
    K = reshape([CBUFspare;1],3,3)';
end

function avgFrame = averageFrame(frame)
    meanNoZero = @(m) sum(double(m),3)./sum(m~=0,3);
    collapseM = @(x) meanNoZero(reshape([frame.(x)],size(frame(1).(x),1),size(frame(1).(x),2),[]));
    avgFrame.z=uint16(collapseM('z'));
    avgFrame.i=uint8(collapseM('i'));
    avgFrame.c=uint8(collapseM('c'));
end

