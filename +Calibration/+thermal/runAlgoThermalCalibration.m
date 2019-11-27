function  [calibPassed] = runAlgoThermalCalibration(runParamsFn,calibParamsFn, fprintff,spark,app)
    t=tic;
    results = struct;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    if(~exist('spark','var'))
        spark=[];
    end
    if(~exist('app','var'))
        app=[];
    end
    % clear calib_temp
    if(exist(ivcam2tempdir,'dir'))
        rmdir(ivcam2tempdir,'s');
    end
    write2spark = ~isempty(spark);
    
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);
    
    if noCalibrations(runParams)
        calibPassed = -1;
        return;
    end
    %% output all RegState to files 
    RegStateSetOutDir(runParams.outputFolder);

    %% Calibration file names
    mkdirSafe(runParams.outputFolder);
    runParams.internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');
    [fnCalib,fnUndsitLut] = Calibration.aux.defineFileNamesAndCreateResultsDir(runParams.internalFolder, runParams.configurationFolder);
    
    fprintff('Starting calibration:\n');
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f.%1.0f\n','version',runParams.version,runParams.subVersion);
    
    %% Load init fw
    fprintff('Loading initial firmware...');
    initFolder = runParams.internalFolder;
    fw = Pipe.loadFirmware(initFolder,'tablesFolder',initFolder);
    fw.get();%run autogen
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Load hw interface
    hw = loadHWInterface(runParams,fw,fprintff,t);
    [~,serialNum,~] = hw.getInfo(); 
    fprintff('%-15s %8s\n','serial',serialNum);
    
    %% call HVM_cal_init
    calib_dir = fileparts(fnCalib);
    [calibParams , ~] = HVM_Cal_init(calibParamsFn,calib_dir,fprintff,runParams.outputFolder);

    
    %% Start stream to load the configuration
    Calibration.aux.collectTempData(hw,runParams,fprintff,'Before starting stream:');
    
    %% Init hw configuration
    initConfiguration(hw,fw,runParams,calibParams,fprintff,t);

    %% Stream initiation
    hw.cmd('DIRTYBITBYPASS');
    hw.setAlgoLoops(false, false); % (sync loop, thermal loop)
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    hw.setPresetControlState(calibParams.gnrl.presetMode);
    
    fprintff('Opening stream...');
%     Calibration.aux.startHwStream(hw,runParams);
    hw.startStream(0,runParams.calibRes);
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Set coarse DSM values %TODO: remove completely
    % calibrateCoarseDSM(hw, runParams, calibParams, fprintff,t);
    
    %% Get a frame to see that hwinterface works.
    fprintff('Capturing frame...');
    hw.getFrame();
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% ::calibrate delays::
    [results, calibPassed ,delayRegs] = Calibration.dataDelay.calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff, false);
    if ~calibPassed
        return;
    end
    % start cooling procedure
    hw.stopStream;
    fprintff('Done(%ds)\n',round(toc(t)));
    
    fprintff('[-] Thermal loop calibration...\n');
    if runParams.thermalLoop
        %% load EPROM structure suitible for calib version tool
        [regs, luts, eepromRegs, eepromBin] = Calibration.thermal.readDFZRegsForThermalCalculation(hw, false, calibParams, runParams);
        regs.EXTL.conLocDelaySlow       = delayRegs.EXTL.conLocDelaySlow;
        regs.EXTL.conLocDelayFastC      = delayRegs.EXTL.conLocDelayFastC;
        regs.EXTL.conLocDelayFastF      = delayRegs.EXTL.conLocDelayFastF;
        regs.FRMW.conLocDelayFastSlope  = delayRegs.FRMW.conLocDelayFastSlope;
        regs.FRMW.conLocDelaySlowSlope  = delayRegs.FRMW.conLocDelaySlowSlope;
        regs.FRMW.dfzCalTmp             = delayRegs.FRMW.dfzCalTmp;

        if typecast(hw.read('DESTtmptrOffset'),'single') ~= 0
            error('Algo thermal loop was active. Please disconnect and reconnect the unit before running.');
        end
        % thermal calibration
        maxCoolTime = inf;
        maxHeatTime = calibParams.warmUp.maxWarmUpTime;
        if runParams.coolDown
            coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,maxCoolTime); % cool down
        end
        [calibPassed, results] = Calibration.thermal.AlgoThermalCalib(hw, regs, eepromRegs, eepromBin, calibParams, runParams, fw, fnCalib, results, fprintff, maxHeatTime, app);
    else
        fprintff('skipped\n');
    end
    
    Calibration.aux.logResults(results,runParams);
    Calibration.aux.writeResults2Spark(results,spark,calibParams.errRange,write2spark,'Cal');
    
    fprintff('[!] Calibration ended - ');
    if(calibPassed==0)
        fprintff('FAILED.\n');
    else %% burn tables
        fprintff('PASSED.\n');
        fprintff('Burning algo thermal table...');
        if runParams.burnCalibrationToDevice
            thermalTableFileName = Calibration.aux.genTableBinFileName('Algo_Thermal_Loop_CalibInfo', calibParams.tableVersions.algoThermal);
            thermalTableFullPath = fullfile(runParams.outputFolder, thermalTableFileName);
            try
                cmdstr = sprintf('WrCalibInfo %s',thermalTableFullPath);
                hw.cmd(cmdstr);
                fprintff('Done\n');
            catch
                fprintf('Failed to write Algo_Thermal_Table to EPROM. You are probably using an unsupported fw version.\n');
                calibPassed = 0;
            end
            fprintff('Burning algo calibration table...');
            algoTableFileName = Calibration.aux.genTableBinFileName('Algo_Calibration_Info_CalibInfo', calibParams.tableVersions.algoCalib);
            algoTableFullPath = fullfile(runParams.outputFolder, algoTableFileName);
            try
                cmdstr = sprintf('WrCalibInfo %s',algoTableFullPath);
                hw.cmd(cmdstr);
                fprintff('Done\n');
                calibPassed = 1;
            catch
                fprintf('Failed to write Algo_Calibration_Info to EPROM. You are probably using an unsupported fw version.\n');
                calibPassed = 0;
            end
        else
            fprintff('skipped\n')
        end
    end
    clear hw;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn)
    runParams=xml2structWrapper(runParamsFn);
    calibParams = xml2structWrapper(calibParamsFn);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hw = loadHWInterface(runParams,fw,fprintff,t)
    fprintff('Loading HW interface...');
    if isfield(runParams,'replayFile')
        hwRecFile = runParams.replayFile;
    else
        hwRecFile = [];
    end
    
    if runParams.replayMode
        if(exist(hwRecFile,'file'))
            % Use recorded session
            hw=HWinterfaceFile(hwRecFile);
            fprintff('Loading recorded capture(%s)\n',hwRecFile);
            
        else
            error('no file found in %s\n',hwRecFile)
        end
    else
        hw=HWinterface(fw,fullfile(runParams.outputFolder,'sessionRecord.mat'));
        
    end
    fprintff('Done(%ds)\n',round(toc(t)));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function initConfiguration(hw,fw,runParams,calibParams,fprintff,t)  
    fprintff('init hw configuration...');
    if(runParams.init)
        % Create config calib files
        fprintff('[-] Burning default config calib files...');
        GenInitCalibTables_Calc(calibParams, '');
        hw.burnCalibConfigFiles(fullfile(runParams.internalFolder,'initialCalibFiles'));
        hw.cmd('rst');
        pause(10);
        fprintff('Done\n');
    else
        fprintff('skipped\n');
    end
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

function calibrateCoarseDSM(hw, runParams, calibParams, fprintff, t)
    % Set a DSM value that makes the valid area of the image in spherical
    % mode to be above a certain threshold.
    fprintff('[-] Coarse DSM calibration...\n');
    if(runParams.DSM)
        Calibration.DSM.DSM_CoarseCalib(hw,calibParams,runParams);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function res = noCalibrations(runParams)
    res = ~(runParams.DSM || runParams.dataDelay || runParams.init);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RegStateSetOutDir(Outdir)
    global g_reg_state_dir;
    g_reg_state_dir = Outdir;
end
