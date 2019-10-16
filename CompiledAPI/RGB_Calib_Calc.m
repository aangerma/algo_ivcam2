function [rgbPassed, rgbTable, results] = RGB_Calib_Calc(InputPath, calibParams, irImSize, Kdepth, z2mm)
% description: calculates the calibration between the IR/Depth images and
% the RGB images
%regs_reff
% inputs:
%   InputPath -  path for input images  dir stucture InputPath\PoseN N =1:5
%        note 
%           I image naming I_*_000n.bin
%   calibParams - calibparams strcture.
%                                  
% output:
% rgbPassed - <bool> Calibration suceeded 
% rgbTable - <vector> contains the data that will make the rgb table 
% results - <struct> with two interesting fields: rgbIntReprojRms,rgbExtReprojRms

    t0 = tic;
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn g_countRuntime; % g_regs g_luts;
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
    runParams.outputFolder = g_output_dir;

    [im,rgbs] = loadRGBFrames(InputPath,irImSize,calibParams);
    
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'InputPath' , 'calibParams' ,'Kdepth' , 'irImSize' ,'z2mm');
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn,'im' ,'rgbs', 'calibParams' ,'Kdepth' , 'runParams','runParams' ,'z2mm');
    end
    [rgbPassed, rgbTable, results] = RGB_Calib_Calc_int(im, rgbs, calibParams, Kdepth, fprintff, runParams, z2mm);

    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'rgbPassed','rgbTable','results');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nRGB_Calib_Calc run time = %.1f[sec]\n', t1);
    end
end

function [im,rgbs] = loadRGBFrames(imagePath,IrImSize,calibParams)
    poses = dirFolders(imagePath);
    IrImSize = flip(IrImSize);
    for i=1:length(poses)
        filesIR = dirFiles(fullfile(imagePath,poses{i}),'I*',1);
        filesRGB = dirFiles(fullfile(imagePath,poses{i}),'RGB*',1);
        img = readAllBytes(filesIR{1});
        im(i).i = rot90(reshape(img,flip(IrImSize)),2);
	    z = Calibration.aux.GetFramesFromDir(fullfile(imagePath,poses{i}),IrImSize(1), IrImSize(2),'Z');
        im(i).z = rot90(mean(z,3),2);
        img = typecast(readAllBytes(filesRGB{1}),'uint16');
        rgbs{i} = reshape(double(bitand(img,255)),calibParams.rgb.imSize)';
    end
end
