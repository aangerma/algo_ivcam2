function [finishedHeating, calibPassed, results, metrics, metricsWithTheoreticalFix, Invalid_Frames] = TmptrDataFrame_Calc(finishedHeating, regs, eepromRegs, eepromBin, FrameData, sz, frameBytes, calibParams, maxTime2Wait)

%function [result, data ,table]  = TemDataFrame_Calc(regs, FrameData, sz ,InputPath,calibParams, maxTime2Wait)
% description: initiale set of the DSM scale and offset 
%
% inputs:
%   regs      - register list for calculation (zNorm ,kRaw ,hbaseline
%   ,baseline ,xfov ,yfov ,laserangleH ,laserangleV)
%   FrameData - structure of device state during frame capturing (varity temprature sensor , iBias , vBias etc) 
%   frameBytes - images (in bytes sequence form)
%
% output:
%   result
%       <-1> - error
%        <0> - table not complitted keep calling the function with another samples point.
%        <1> - table ready
%   tableResults
%   metrics - validation metrics relvent only on last phase when table
%   ready
%   invalid_Frames - number of invalid frames relvent only on last phase when table
%   ready
%
    t0 = tic;
    global g_output_dir g_calib_dir g_save_input_flag g_save_output_flag g_skip_thermal_iterations_save g_fprintff g_temp_count g_LogFn g_countRuntime;
    
    % auto-completions
    if isempty(g_temp_count)
        g_temp_count = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_skip_thermal_iterations_save)
        g_skip_thermal_iterations_save = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);

    % input save
    if ~g_skip_thermal_iterations_save && g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' ,[func_name sprintf('_in%d.mat',g_temp_count)]);
        save(fn,'finishedHeating', 'regs', 'eepromRegs', 'eepromBin', 'FrameData', 'sz', 'frameBytes', 'calibParams', 'maxTime2Wait');
    end
    
    % operation
    height = sz(1);
    width  = sz(2);
    if (isempty(eepromRegs) || ~isstruct(eepromRegs))
        eepromRegs = extractEepromRegs(eepromBin, g_calib_dir);
        regs = struct_merge(eepromRegs, regs);
    end
    origFinishedHeating = finishedHeating;
    
    [finishedHeating, calibPassed, results, metrics,metricsWithTheoreticalFix, Invalid_Frames] = TmptrDataFrame_Calc_int(finishedHeating, regs, eepromRegs, FrameData, height , width, frameBytes, calibParams, maxTime2Wait, output_dir, fprintff, g_calib_dir);
    
    % output save
    if ~g_skip_thermal_iterations_save && g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,  'mat_files' ,[func_name sprintf('_out%d.mat',g_temp_count)]);
        save(fn, 'finishedHeating', 'calibPassed', 'results', 'metrics', 'metricsWithTheoreticalFix', 'Invalid_Frames');
    end
    if (origFinishedHeating~=0)
        g_temp_count = 0;
    else
        g_temp_count = g_temp_count + 1; 
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [merged] = struct_merge(existing , new )
    merged = existing;
    % overriding merged with new
    f = fieldnames(new);
    for i = 1:length(f)
        fn = fieldnames(new.(f{i}));
        for n = 1:length(fn)
            merged.(f{i}).(fn{n}) = new.(f{i}).(fn{n});
        end
    end
end

