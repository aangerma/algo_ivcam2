function [agingRegs, results] = RtdOverAging_Calib_Calc(frameBytes, calibParams, res, z2mm, vddSamples)
    % function [dfzRegs,results] = RtdOverAging_Calib_Calc(frameBytes, calibParams, res, z2mm)
    % description: captures the behavivour of the system delay over vdd
    %regs_reff
    % inputs:
    %   frameBytes - images from different trials and presets (in bytes sequence form)
    %   calibParams - calibparams strcture.
    %   res - resolution for reshaping the images from frameBytes
    %   z2mm - z to mm factor
    %   refVdd - reference vdd of the unit - 
    %
    % output:
    %   agingRegs - frmw register (sampledVddValues)
    
    t0 = tic;
    global g_output_dir g_save_input_flag g_save_output_flag g_countRuntime g_fprintff g_LogFn g_save_internal_input_flag;
    
    % auto-completions
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_internal_input_flag)
        g_save_internal_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);
    
    % input save
    if g_save_input_flag && exist(output_dir,'dir')~=0
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytes', 'calibParams', 'res', 'z2mm', 'vddSamples');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    for iFrame = 1:length(frameBytes)
        im(iFrame) = Calibration.aux.convertBytesToFrames(frameBytes{iFrame}, res, [], true);
    end
    
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'calibParams', 'runParams', 'res', 'z2mm', 'vddSamples');
    end
    [agingRegs, results] = RtdOverAging_Calib_Calc_int(im, calibParams, runParams, res, z2mm, vddSamples);      
 
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'agingRegs', 'results');
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

