function  [calibPassed] = runAlgoThermalValidation(runParamsFn,calibParamsFn, fprintff,spark,app)
    t=tic;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    if(~exist('spark','var'))
        spark=[];
    end
    if(~exist('app','var'))
        app=[];
    end
    write2spark = ~isempty(spark);
    
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);
   
    %% output all RegState to files 
    RegStateSetOutDir(runParams.outputFolder);

    %% Calibration file names
    mkdirSafe(runParams.outputFolder);
    runParams.internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');
    [fnCalib,~] = Calibration.aux.defineFileNamesAndCreateResultsDir(runParams.internalFolder, runParams.configurationFolder);
    
    fprintff('Starting validation v%2.2f:\n',AlgoThermalCalibToolVersion);
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f.%1.0f\n','version',runParams.version,runParams.subVersion);
    
    %% Load hw interface
    hw = HWinterface;
    [~,serialNum,~] = hw.getInfo(); 
    fprintff('%-15s %8s\n','serial',serialNum);
    
    %% call HVM_cal_init
    calib_dir = fileparts(fnCalib);
    [calibParams , ~] = HVM_Cal_init(calibParamsFn,calib_dir,fprintff,runParams.outputFolder);



    %% Stream initiation
    hw.cmd('DIRTYBITBYPASS');
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    hw.setPresetControlState(calibParams.gnrl.presetMode);
    
    fprintff('Opening stream...');
    hw.startStream(0,runParams.calibRes);
    fprintff('Done(%ds)\n',round(toc(t)));
    

    %% Get a frame to see that hwinterface works. Also load registers to unit.
    fprintff('Capturing frame...');
    hw.getFrame();
    hw.stopStream;
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% ::calibrate delays::

    %% load EPROM structure suitible for calib version tool
    unitData = Calibration.thermal.thermalValidationRegsState(hw);

    % thermal calibration
    Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,inf); % cool down

    results = Calibration.thermal.validationIterativeEnvelope(hw, unitData, calibParams, runParams, fprintff);
    
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

function RegStateSetOutDir(Outdir)
    global g_reg_state_dir;
    g_reg_state_dir = Outdir;
end
