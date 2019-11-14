%function [results ,luts] = END_calib_Calc(verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams,undist_flag)
function [results, regs, luts] = END_calib_Calc(roiRegs, dfzRegs, results, fnCalib, calibParams, undist_flag, configurationFolder, eepromRegs, eepromBin)
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
    global g_output_dir g_calib_dir g_save_input_flag g_save_internal_input_flag g_save_output_flag g_fprintff g_LogFn g_countRuntime;
    
    % auto-completions
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_save_internal_input_flag)
        g_save_internal_input_flag = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);
    
    % input save
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'roiRegs', 'dfzRegs', 'results', 'fnCalib', 'calibParams', 'undist_flag', 'configurationFolder', 'eepromRegs', 'eepromBin');
    end
    
    % operation
    runParams.outputFolder          = g_output_dir;
    runParams.undist                = undist_flag;
    runParams.version               = AlgoCameraCalibToolVersion;
    runParams.configurationFolder   = configurationFolder; 
    if (isempty(eepromRegs) || ~isstruct(eepromRegs)) % called from HVM tester
        eepromRegs = extractEepromRegs(eepromBin, g_calib_dir);
    end
    [delayRegs, dsmRegs, thermalRegs, dfzRegs] = Calibration.aux.getATCregsFromEEPROMregs(eepromRegs, dfzRegs);
    
    if g_save_internal_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'runParams', 'delayRegs', 'dsmRegs', 'roiRegs', 'dfzRegs', 'thermalRegs', 'results', 'fnCalib', 'fprintff', 'calibParams');
    end
    [results ,regs, luts] = End_Calib_Calc_int(runParams, delayRegs, dsmRegs, roiRegs, dfzRegs, thermalRegs, results, fnCalib, fprintff, calibParams);
    
    % output save
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files', [func_name '_out.mat']);
        save(fn, 'results', 'regs', 'luts');
    end
    
    % finalization
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\n%s run time = %.1f[sec]\n', func_name, t1);
    end
    if (fid>-1)
        fclose(fid);
    end
end

