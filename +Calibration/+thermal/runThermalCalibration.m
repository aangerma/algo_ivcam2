function  [calibPassed] = runThermalCalibration(runParamsFn,calibParamsFn, fprintff,app)
       
    t=tic;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);
    if ~runParams.performCalibration
       fprintff('Skipping calibration stage...\n'); 
       calibPassed = 1;
       return;
    end
    fprintff('Starting thermal calibration:\n');
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f.%1.0f\n','version',runParams.version,runParams.subVersion);
    
    %% call HVM_cal_init
    cal_output_dir = fileparts(fopen(app.m_logfid));
    [calibParams , ~] = HVM_Cal_init(calibParamsFn,fprintff,cal_output_dir);
    
    %% Load hw interface
    fprintff('Loading HW interface...');
    hw=HWinterface();
    fprintff('Done(%ds)\n',round(toc(t)));
    
    [~,serialNum,isGen1] = hw.getInfo(); 
    fprintff('%-15s %8s\n','serial',serialNum);
    if isGen1
        fprintff('Unit is gen1 ID    \n');
    else
        fprintff('Unit is demo board    \n');
    end
    
    %% Get regs state
    fprintff('Reading unit calibration regs...');

    
    %% Start stream to load the configuration
    hw.cmd('DIRTYBITBYPASS');
    hw.cmd('algo_thermloop_en 0');
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    hw.setPresetControlState(calibParams.gnrl.presetMode);
    hw.getFrame;
    hw.stopStream;
    
    
    data.regs = Calibration.thermal.readDFZRegsForThermalCalculation(hw,1);
    fprintff('Done(%ds)\n',round(toc(t)));
    fprintff('Algo Calib Ldd Temp: %2.2fdeg\n',data.regs.FRMW.dfzCalTmp);
    fprintff('Algo Calib vBias: (%2.2f,%2.2f,%2.2f)\n',data.regs.FRMW.dfzVbias);
    fprintff('Algo Calib iBias: (%2.2f,%2.2f,%2.2f)\n',data.regs.FRMW.dfzIbias);
    data.calibParams = calibParams;
    data.runParams = runParams;
    
    
    if typecast(hw.read('DESTtmptrOffset'),'single') ~= 0
        error('Algo thermal loop was active. Please disconnect and reconnect the unit before running.');
    end
    % thermal calibration 
    maxCoolTime = inf;
    maxHeatTime = inf;
    regs = data.regs;
    coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,maxCoolTime); % call down
    calibPassed = Calibration.thermal.ThermalCalib(hw,regs,calibParams,runParams,fprintff,maxHeatTime,app);

        
    fprintff('[!] Calibration ended - ');
    if(calibPassed==0)
        fprintff('FAILED.\n');
    else %% burn tables
        fprintff('PASSED.\n');
        fprintff('Burning algo thermal table...');
        % tableName
        version = thermalCalibToolVersion;
        whole = floor(version);
        frac = floor(mod(version,1)*100);

        calibpostfix = sprintf('_Ver_%02d_%02d',whole,frac);

        calibParams.fwTable.name = [calibParams.fwTable.name,calibpostfix,'.bin'];
        tableName = fullfile(runParams.outputFolder,calibParams.fwTable.name);
        reservedTableName = fullfile(runParams.outputFolder,filesep,['Reserved_512_Calibration_2_CalibData' calibpostfix '.txt']);
        try 
            cmdstr = sprintf('WrCalibInfo %s',tableName);
            hw.cmd(cmdstr);
            fprintff('Done\n');
        catch
            fprintf('Failed to write Algo_Thermal_Table to EPROM. You are probably using an unsupported fw version.\n');
        end
        fprintff('Reburning Reserved_512_Calibration_2_CalibData...');
        try 
            cmdstr = sprintf('WrCalibData %s',reservedTableName);
            hw.cmd(cmdstr);
            fprintff('Done\n');
        catch
            fprintf('Failed to write Reserved_512_Calibration_2_CalibData to EPROM. You are probably using an unsupported fw version.\n');
        end
    end
    clear hw;
end
function [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn)
    runParams=xml2structWrapper(runParamsFn);
    calibParams = xml2structWrapper(calibParamsFn);
    
end

function [calibParams , ret] = HVM_Cal_init(fn_calibParams,fprintff,output_dir)
    if(~exist('output_dir','var'))
        output_dir = fullfile(tempdir,'\cal_tester\output');
    end
    debug_log_f         = 0;
    verbose             = 0;
    save_input_flag     = 1;
    save_output_flag    = 1;
    dummy_output_flag   = 0;
    ret = 1;
    [calibParams ,~] = cal_init(output_dir,fn_calibParams, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag,fprintff);
end


