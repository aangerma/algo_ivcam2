%function [results ,luts] = END_calib_Calc(verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams,undist_flag)
function [results, regs, luts] = END_calib_Calc(delayRegs, dsmregs, roiRegs, dfzRegs, results, fnCalib, calibParams, undist_flag, version, configurationFolder, eepromRegs, eepromBin, afterThermalCalib_flag)
% the function calcualte the undistored table based on the result from the DFZ and ROI then prepare calibration scripts  
% to burn into the eprom. later on the function will create calibration
% eprom table. the FW will process them and set the registers as needed. 
%
% inputs:
%   delayRegs    - output of the of IR/Z delay (the actual setting value as in setabsDelay fundtion)
%   dsmregs      - output of the DSM_Calib_Calc
%   roiRegs      - output of the ROI_Calib_Calc
%   dfzRegs      - output of the DFZ_Calib_Calc
%   results      - incrmental result of prev algo.
%   fnCalib      - base directory of calib/config files (calib.csv ,
%   config.csv , mode.csv)
%   calibParams  - calibration params.
%                                  
% output:
%   results - incrmntal result 
%   luts - undistort table.

    t0 = tic;
    if ~exist('afterThermalCalib_flag','var')
        afterThermalCalib_flag = 0;
    end
    global g_output_dir g_calib_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn g_countRuntime; % g_regs g_luts;
    % setting default global value in case not initial in the init function;
    if isempty(g_debug_log_f)
        g_debug_log_f = 0;
    end
    if isempty(g_verbose)
        g_verbose = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_dummy_output_flag)
        g_dummy_output_flag = 0;
    end
    
    func_name = dbstack;
    func_name = func_name(1).name;
    
    
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(g_output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(g_output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end

    
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'delayRegs', 'dsmregs', 'roiRegs', 'dfzRegs', 'results', 'fnCalib', 'calibParams', 'undist_flag', 'version', 'configurationFolder', 'eepromRegs', 'eepromBin', 'afterThermalCalib_flag');
    end
    runParams.outputFolder = g_output_dir;
    runParams.undist = undist_flag;
    runParams.afterThermalCalib = afterThermalCalib_flag;
    runParams.version=version;
    runParams.configurationFolder=configurationFolder; 
 
    fw = Firmware(g_calib_dir);
    if(isempty(eepromRegs) || ~isstruct(eepromRegs)) % called from HVM tester
        EPROMstructure  = load(fullfile(g_calib_dir,'eepromStructure.mat'));
        EPROMstructure  = EPROMstructure.updatedEpromTable;
        eepromBin       = uint8(eepromBin);
        eepromRegs      = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
    end
    [dfzRegs, thermalRegs] = getThermalRegs(dfzRegs, eepromRegs, runParams.afterThermalCalib);
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'runParams', 'delayRegs', 'dsmregs', 'roiRegs', 'dfzRegs', 'thermalRegs', 'results', 'fnCalib', 'calibParams');
    end
    [results ,regs, luts] = End_Calib_Calc_int(runParams, delayRegs, dsmregs, roiRegs, dfzRegs, thermalRegs, results, fnCalib, fprintff, calibParams);    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files', [func_name '_out.mat']);
        save(fn, 'results', 'regs','luts');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nEND_calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end



function [dfzRegs, thermalRegs] = getThermalRegs(dfzRegs, eepromRegs, afterThermalCalib)
    if afterThermalCalib
        [~, ~, thermalRegs, dfzRegs] = Calibration.aux.getATCregsFromEEPROMregs(eepromRegs, dfzRegs);
    else % dfzRegs was already enriched in DFZ_calib, thermalRegs are irrelevant
        thermalRegs.FRMW.atlMinVbias1   = single(1);
        thermalRegs.FRMW.atlMaxVbias1   = single(3);
        thermalRegs.FRMW.atlMinVbias2   = single(1);
        thermalRegs.FRMW.atlMaxVbias2   = single(3);
        thermalRegs.FRMW.atlMinVbias3   = single(1);
        thermalRegs.FRMW.atlMaxVbias3   = single(3);
    end
end