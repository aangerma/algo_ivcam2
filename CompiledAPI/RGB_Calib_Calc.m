function [rgbPassed, rgbTable, results] = RGB_Calib_Calc(frameBytes, calibParams, irImSize, Kdepth, z2mm, rgbCalTemperature,rgbThermalBinData)
% description: calculates the calibration between the IR/Depth images and
% the RGB images
%regs_reff
% inputs:
%   frameBytes - images (in bytes sequence form)
%   calibParams - calibparams strcture.
%   rgbCalTemperature - The tempeartue in which the RGB frames where taken                               
% output:
% rgbPassed - <bool> Calibration suceeded 
% rgbTable - <vector> contains the data that will make the rgb table 
% results - <struct> with two interesting fields: rgbIntReprojRms,rgbExtReprojRms

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
    if g_save_input_flag && exist(g_output_dir,'dir')~=0
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn, 'frameBytes', 'calibParams', 'irImSize', 'Kdepth', 'z2mm', 'rgbCalTemperature');
    end
    
    % operation
    im = Calibration.aux.convertBytesToFrames(frameBytes, irImSize, flip(calibParams.rgb.imSize), true);
    rgbs = {im.yuy2}; % extracting RGB images
    im = rmfield(im, 'yuy2'); % disposing of RGB images
    im = arrayfun(@(x) struct('i',rot90(x.i,2),'z',rot90(x.z,2)), im);    
    runParams.outputFolder = g_output_dir;
    
    if g_save_internal_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'rgbs', 'calibParams', 'Kdepth', 'fprintff', 'runParams', 'z2mm', 'rgbCalTemperature');
    end
    [rgbPassed, rgbTable, results] = RGB_Calib_Calc_int(im, rgbs, calibParams, Kdepth, fprintff, runParams, z2mm, rgbCalTemperature,rgbThermalBinData);

    % output save
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'rgbPassed', 'rgbTable', 'results');
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

