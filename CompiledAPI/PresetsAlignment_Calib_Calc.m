function results = PresetsAlignment_Calib_Calc(frameBytes, nPresets, calibParams, res, z2mm)
    % function [dfzRegs,results,calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs,regs_reff)
    % description: initiale set of the DSM scale and offset
    %regs_reff
    % inputs:
    %   frameBytes - images from different trials and presets (in bytes sequence form)
    %   nPresets - number of presets compared
    %   calibParams - calibparams strcture.
    %   DFZ_regs - list of hw regs values and FW regs
    %
    % output:
    %   dfzRegs - frmw register (fov , polyvars, projectionYshear, laserangleH/V
    %   results - geomErr:  and extraImagesGeomErr:
    %   calibPassed - pass fail
    %
    
    t0 = tic;
    global g_output_dir g_save_input_flag g_save_internal_input_flag g_save_output_flag g_fprintff g_LogFn g_countRuntime;
    
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
        save(fn, 'frameBytes', 'nPresets', 'calibParams', 'res', 'z2mm');
    end
    
    % operation
    runParams.outputFolder = output_dir;
    for iPose = 1:length(frameBytes)
        im(iPose) = Calibration.aux.convertBytesToFrames(frameBytes{iPose}, res, [], true);
    end
    im = reshape(im, nPresets, [])';
    
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'calibParams', 'runParams', 'z2mm', 'res');
    end
    [results] = PresetsAlignment_Calib_Calc_int(im, calibParams, runParams, z2mm, res);       
    
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'results');
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

