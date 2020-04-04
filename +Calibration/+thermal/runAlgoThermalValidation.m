function validPassed = runAlgoThermalValidation(runParamsFn, calibParamsFn, fprintff, spark, app)
    t = tic;
    if (~exist('fprintff','var'))
        fprintff = @(varargin) fprintf(varargin{:});
    end
    if (~exist('spark','var'))
        spark = [];
    end
    if (~exist('app','var'))
        app = [];
    end
    write2spark = ~isempty(spark);
    
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams, calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);
   
    % output all RegState to files 
    RegStateSetOutDir(runParams.outputFolder);

    % Calibration file names
    mkdirSafe(runParams.outputFolder);
    runParams.internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');
    [fnCalib,~] = Calibration.aux.defineFileNamesAndCreateResultsDir(runParams.internalFolder, runParams.configurationFolder);
    
    fprintff('Starting validation v%2.2f:\n',AlgoThermalCalibToolVersion);
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f.%1.0f\n','version',runParams.version,runParams.subVersion);
    
    % Load hw interface
    hw = HWinterface;
    [~,serialNum,~] = hw.getInfo(); 
    fprintff('%-15s %8s\n','serial',serialNum);
    
    % call HVM_cal_init
    calib_dir = fileparts(fnCalib);
    [calibParams , ~] = HVM_Cal_init(calibParamsFn,calib_dir,fprintff,runParams.outputFolder);

    % Stream initiation
    hw.cmd('DIRTYBITBYPASS');
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    hw.setPresetControlState(calibParams.gnrl.presetMode);
    
    fprintff('Opening stream...');
    hw.startStream(0,runParams.calibRes);
    fprintff('Done(%ds)\n',round(toc(t)));

    % Get a frame to see that hwinterface works. Also load registers to unit.
    fprintff('Capturing frame...');
    hw.getFrame();
    hw.stopStream;
    fprintff('Done(%ds)\n',round(toc(t)));
    
    % load EPROM structure suitible for calib version tool
    unitData = thermalValidationRegsState(hw);

    % thermal calibration
    Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,inf); % cool down

    [results, validPassed] = validationIterativeEnvelope(hw, unitData, calibParams, runParams, fprintff);
    
    Calibration.aux.logResults(results,runParams);
    Calibration.aux.writeResults2Spark(results,spark,calibParams.errRange,write2spark,'Val');
    
    fprintff('[!] Validation ended - ');
    if(validPassed==0)
        fprintff('FAILED.\n');
    else 
        fprintff('PASSED.\n');
    end
    clear hw;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn)
    runParams=xml2structWrapper(runParamsFn);
    calibParams = xml2structWrapper(calibParamsFn);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RegStateSetOutDir(Outdir)
    global g_reg_state_dir;
    g_reg_state_dir = Outdir;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [calibParams , ret] = HVM_Cal_init(fn_calibParams,calib_dir,fprintff,output_dir)
    % Sets all global variables
    if(~exist('output_dir','var'))
        output_dir = fullfile(ivcam2tempdir,'\cal_tester\output');
    end
    save_input_flag                 = 1;
    save_internal_input_flag        = 0;
    save_output_flag                = 1;
    skip_thermal_iterations_save    = 0;
    ret                             = 1;
    [calibParams ,~] = cal_init(output_dir, calib_dir, fn_calibParams, save_input_flag, save_internal_input_flag, save_output_flag, skip_thermal_iterations_save, fprintff);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [unitData  ] = thermalValidationRegsState( hw )
    [~,unitData.eepromBin] = hw.readAlgoEEPROMtable();
    [~,unitData.diggUndistBytes] = hw.cmd('mrdfull 85100000 85102000');
    % luts.DIGG.undistModel = typecast(diggUndistBytes(:),'int32');
    unitData.regs.GNRL.imgHsize = uint16(hw.read('GNRLimgHsize'));
    unitData.regs.GNRL.imgVsize = uint16(hw.read('GNRLimgVsize'));
    unitData.regs.DEST.baseline = typecast(hw.read('DESTbaseline$'),'single');
    unitData.regs.DEST.baseline2 = typecast(hw.read('DESTbaseline2'),'single');
    unitData.regs.DEST.hbaseline = hw.read('DESThbaseline');
    unitData.kWorld = hw.getIntrinsics();
    unitData.regs.GNRL.zNorm = single(hw.z2mm);
    unitData.regs.GNRL.zMaxSubMMExp = uint16(hw.read('GNRLzMaxSubMMExp'));
    %     regs.FRMW.mirrorMovmentMode = 1;
    %     regs.MTLB.fastApprox = ones(1,8,'logical');
    %     regs.DIGG.sphericalEn	= logical(hw.read('DIGGsphericalEn'));
    %     regs.DIGG.sphericalOffset	= typecast(hw.read('DIGGsphericalOffset'),'int16');
    %     regs.DIGG.sphericalScale 	= typecast(hw.read('DIGGsphericalScale'),'int16');
    %     regs.DEST.p2axa = hex2single(dec2hex(hw.read('DESTp2axa')));
    %     regs.DEST.p2axb = hex2single(dec2hex(hw.read('DESTp2axb')));
    %     regs.DEST.p2aya = hex2single(dec2hex(hw.read('DESTp2aya')));
    %     regs.DEST.p2ayb = hex2single(dec2hex(hw.read('DESTp2ayb')));
    
    %     regs.FRMW.kWorld = hw.getIntrinsics();
    %     regs.FRMW.kRaw = regs.FRMW.kWorld;
    %     regs.FRMW.kRaw(7) = single(regs.GNRL.imgHsize) - 1 - regs.FRMW.kRaw(7);
    %     regs.FRMW.kRaw(8) = single(regs.GNRL.imgVsize) - 1 - regs.FRMW.kRaw(8);
    %     regs.GNRL.zNorm = hw.z2mm;
    [~,unitData.rgbCalibData] = hw.cmd('READ_TABLE 10 0');
    [~,unitData.rgbThermalData] = hw.cmd('READ_TABLE 17 0');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [results, validPassed] = validationIterativeEnvelope(hw, unitData, calibParams, runParams, fprintff)
    
    %tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
    tempTh = calibParams.warmUp.warmUpTh;
    timeBetweenFrames = calibParams.warmUp.timeBetweenFrames;
    %maxTime2WaitSec = maxTime2Wait*60;
    
    pN = 1000;
    tempsForPlot = nan(1,pN);
    timesForPlot = nan(1,pN);
    plotDataI = 1;
    
    % isXGA = all(runParams.calibRes==[768,1024]);
    % if isXGA
    %     hw.cmd('ENABLE_XGA_UPSCALE 1');
    % end
    runParams.rgb = calibParams.gnrl.rgb.doStream;
    runParams.rgbRes = calibParams.gnrl.rgb.res;
    Calibration.aux.startHwStream(hw,runParams);
    thermalValidationInit(hw,runParams);
    
    prevTmp = hw.getLddTemperature();
    prevTime = 0;
    tempsForPlot(plotDataI) = prevTmp;
    timesForPlot(plotDataI) = prevTime/60;
    plotDataI = mod(plotDataI,pN)+1;
    
    startTime = tic;
    % Collect data until temperature doesn't raise any more
    finishedHeating = false; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next
    
    fprintff('[-] Starting heating stage (waiting for diff<%1.1f over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
    fprintff('Ldd temperatures: %2.2f',prevTmp);
    
    i = 0;
    tempFig = figure(190789);
    plot(timesForPlot,tempsForPlot); grid on, xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));
    
    %framesData = zeros(1,1000000); %
    sz = hw.streamSize();
    % ATCpath_temp = fullfile(ivcam2tempdir,'ATC');
    % if(exist(ATCpath_temp,'dir'))
    %     rmdir(ATCpath_temp,'s');
    % end
    while ~finishedHeating
        % collect data without performing any calibration
        i = i + 1;
        [frameBytes, framesData(i)] = prepareFrameData(hw,startTime,calibParams);
        [finishedHeating,~, ~] = ThermalValidationDataFrame_Calc(finishedHeating, unitData, framesData(i),sz, frameBytes, calibParams);
        
        
        
        if tempFig.isvalid
            tempsForPlot(plotDataI) = framesData(i).temp.ldd;
            timesForPlot(plotDataI) = framesData(i).time/60;
            figure(190789);plot(timesForPlot([plotDataI+1:pN,1:plotDataI]),tempsForPlot([plotDataI+1:pN,1:plotDataI])); grid on, xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));drawnow;
            plotDataI = mod(plotDataI,pN)+1;
        end
        pause(timeBetweenFrames);
        if i == 4
            sceneFig = figure(190790);
            imshow(rot90(hw.getFrame().i,2));
            title('Scene Image');
        end
    end
    hw.stopStream;
    fprintff('Stopped Stream...\n');
    if finishedHeating % always true at this point
        [~,validPassed, resultsThermal] = ThermalValidationDataFrame_Calc(finishedHeating, unitData, framesData(end),sz, frameBytes, calibParams);
        fnames = fieldnames(resultsThermal);
        for iField = 1:length(fnames)
            results.(fnames{iField}) = resultsThermal.(fnames{iField});
        end
    end
    
    
    if i >=4 && sceneFig.isvalid
        close(sceneFig);
    end
    if tempFig.isvalid
        close(tempFig);
    end
    
    hw.stopStream;
    fprintff('Done\n');
    
    % if manualSkip
    %     reason = 'Manual skip';
    % elseif reachedRequiredTempDiff
    %     reason = 'Stable temperature';
    % elseif reachedTimeLimit
    %     reason = 'Passed time limit';
    % elseif reachedCloseToTKill
    %     reason = 'Reached close to TKILL';
    % elseif raisedFarAboveCalibTemp
    %     reason = 'Raised far above calib temperature';
    % end
    % fprintff('Finished heating reason: %s\n',reason);
    
    
    heatTimeVec = [framesData.time];
    tempVec = [framesData.temp];
    LddTempVec = [tempVec.ldd];
    
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        plot(heatTimeVec,LddTempVec)
        title('Heating Stage'); grid on;xlabel('sec');ylabel('ldd temperature [degrees]');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('LddTempOverTime'),1);
        
        ff = Calibration.aux.invisibleFigure;
        plot(heatTimeVec,[tempVec.ma])
        title('Heating Stage'); grid on;xlabel('sec');ylabel('ma temperature [degrees]');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MaTempOverTime'),1);
        
        ff = Calibration.aux.invisibleFigure;
        plot(heatTimeVec,[tempVec.mc])
        title('Heating Stage'); grid on;xlabel('sec');ylabel('mc temperature [degrees]');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('McTempOverTime'),1);
        
        ff = Calibration.aux.invisibleFigure;
        plot(heatTimeVec,[tempVec.tsense])
        title('Heating Stage'); grid on;xlabel('sec');ylabel('Apd temperature [degrees]');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('ApdTempOverTime'),1);
        
    end
    info.duration = heatTimeVec(end);
    info.startTemp = LddTempVec(1);
    info.endTemp = LddTempVec(end);
    
    
    if manualCaptures
        app.stopWarmUpButton.Visible = 'off';
        app.stopWarmUpButton.Enable = 'off';
        Calibration.aux.globalSkip(1,0);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function thermalValidationInit(hw,runParams)
    hw.cmd('mwd a00e1890 a00e1894 00000001 // JFILinvBypass');
    hw.cmd('mwd a00e15f0 a00e15f4 00000001 // JFILgrad1bypass');
    hw.cmd('mwd a00e166c a00e1670 00000001 // JFILgrad2bypass');
    confScriptFldr = fullfile(runParams.outputFolder,'AlgoInternal','confAsDC.txt');
    hw.runScript(confScriptFldr);
    hw.shadowUpdate;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [frameBytes, frameData] = prepareFrameData(hw,startTime,calibParams)
    %    frame = hw.getFrame();
    %    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , nof_frames , path(i));

    [frameData.temp.ldd,frameData.temp.mc,frameData.temp.ma,frameData.temp.apd] = hw.getLddTemperature;
    frameData.temp.shtw2 = hw.getHumidityTemperature;
    for j = 1:3
        [frameData.iBias(j), frameData.vBias(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
    end
    if calibParams.gnrl.rgb.doStream
        frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZICrgb', calibParams.gnrl.Nof2avg);
    else
        frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZIC', calibParams.gnrl.Nof2avg);
    end
    frameData.time = toc(startTime);
%     frameData.flyback = hw.cmd('APD_FLYBACK_VALUES_GET');
%     frameData.maVoltage = hw.getMaVoltagee();
    % RX tracking
end

