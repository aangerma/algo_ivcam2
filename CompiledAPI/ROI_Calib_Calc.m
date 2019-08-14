function [roiRegs,results,fovData] = ROI_Calib_Calc(InputPath, calibParams, ROIregs,results)
% description: initiale set of the DSM scale and offset 
%regs_reff
% inputs:
%   InputPath -  path for input images  dir stucture InputPath\
%               \IR_down
%               \IR_up
%               \IR_Noise
%        note 
%           I image naming I_*_000n.bin
%   calibParams - calibparams strcture.
%   ROIregs - list of hw regs values and FW regs
%                                  
% output:
%   dfzRegs - frmw register (fov , polyvars, projectionYshear, laserangleH/V
%   results - geomErr:  and extraImagesGeomErr:
%   calibPassed - pass fail 
%

    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn;
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

    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir,'roi_temp');
    else
        output_dir = g_output_dir;
    end
    
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end

    
    runParams.outputFolder = output_dir;
    % save Input
    regs = ConvertROIReg(ROIregs);
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'InputPath', 'calibParams' , 'ROIregs','regs');
    end
    [roiRegs,results,fovData] = ROI_Calib_Calc_int(InputPath, calibParams, regs,runParams,results);
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'roiRegs', 'results','fovData');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

function [roiRegs,results,fovData] = ROI_Calib_Calc_int(InputPath, calibParams, ROI_regs,runParams,results)
    width = ROI_regs.GNRL.imgHsize;
    hight = ROI_regs.GNRL.imgVsize;
    [imUbias,imDbias] = GetROIImages(InputPath,width,hight);
    fn = fullfile(runParams.outputFolder, 'mat_files' , 'ROI_im.mat');
        save(fn,'imUbias','imDbias','ROI_regs','calibParams','runParams');
    [roiRegs] = Calibration.roi.calibROIFromZ(imUbias,imDbias,ROI_regs,calibParams,runParams);
    fovData = Calibration.validation.calculateFOVFromZ(imUbias,imDbias,ROI_regs,calibParams,runParams);
    results.upDownFovDiff = sum(abs(fovData.laser.minMaxAngYup-fovData.laser.minMaxAngYdown));
end

function  [ROIregs] = ConvertROIReg(regs)
    mode = regs.FRMWmirrorMovmentMode;
    ROIregs.DIGG.sphericalOffset        = typecast(bitand(regs.DIGGsphericalOffset,hex2dec('0fff0fff')),'int16');
    ROIregs.DIGG.sphericalScale         = typecast(bitand(regs.DIGGsphericalScale ,hex2dec('0fff0fff')),'int16');
    ROIregs.GNRL.imgHsize               = uint16(regs.GNRLimgHsize);
    ROIregs.GNRL.imgVsize               = uint16(regs.GNRLimgVsize);
    ROIregs.FRMW.mirrorMovmentMode      = regs.FRMWmirrorMovmentMode; % uint16         (1)
    ROIregs.FRMW.marginB                = regs.FRMWmarginB;           % int16          (0)
    ROIregs.FRMW.marginL                = regs.FRMWmarginL;           % int16          (0)
    ROIregs.FRMW.marginR                = regs.FRMWmarginR;           % int16          (0)
    ROIregs.FRMW.marginT                = regs.FRMWmarginT;           % int16          (0)
    ROIregs.FRMW.guardBandH             = regs.FRMWguardBandH;        % single         (0)
    ROIregs.FRMW.guardBandV             = regs.FRMWguardBandV;        % single         (0)
    ROIregs.FRMW.xfov(mode)             = regs.FRMWxfov(mode);        % single         (65)
    ROIregs.FRMW.yfov(mode)             = regs.FRMWyfov(mode);        % single         (45)
    ROIregs.FRMW.projectionYshear(mode) = regs.FRMWprojectionYshear(mode); % single   (0)
    ROIregs.FRMW.laserangleH            = regs.FRMWlaserangleH;            % single   (0)
    ROIregs.FRMW.laserangleV 			= regs.FRMWlaserangleV;            % single   (0)
    ROIregs.FRMW.xres 					= regs.FRMWxres;                   % uint16   (640)
    ROIregs.FRMW.yres 					= regs.FRMWyres;                   % uint16   (360)
    ROIregs.FRMW.polyVars 				= regs.FRMWpolyVars;               % single x3[0 0 0]
    ROIregs.FRMW.pitchFixFactor 		= regs.FRMWpitchFixFactor;         % single (0)
    
    ROIregs.FRMW.undistAngHorz      = regs.FRMWundistAngHorz;
    ROIregs.FRMW.undistAngVert      = regs.FRMWundistAngVert;
    ROIregs.FRMW.fovexExistenceFlag = regs.FRMWfovexExistenceFlag;
    ROIregs.FRMW.fovexNominal       = regs.FRMWfovexNominal;
    ROIregs.FRMW.fovexLensDistFlag  = regs.FRMWfovexLensDistFlag;
    ROIregs.FRMW.fovexRadialK       = regs.FRMWfovexRadialK;
    ROIregs.FRMW.fovexTangentP      = regs.FRMWfovexTangentP;
    ROIregs.FRMW.fovexCenter        = regs.FRMWfovexCenter;

end

function [imUbias,imDbias] = GetROIImages(InputPath,width,hight)
    path_up     = fullfile(InputPath,'ZIR_up');
    path_down   = fullfile(InputPath,'ZIR_down');
    imUbias.i = Calibration.aux.GetFramesFromDir(path_up,width, hight,'I');
    imUbias.z = Calibration.aux.GetFramesFromDir(path_up,width, hight,'Z');
    imDbias.i = Calibration.aux.GetFramesFromDir(path_down,width, hight,'I');
    imDbias.z = Calibration.aux.GetFramesFromDir(path_down,width, hight,'Z');
        
    global g_output_dir g_save_input_flag; 
    if g_save_input_flag % save 
        fn = fullfile(g_output_dir, 'mat_files' , 'ROI_im.mat');
        save(fn,'imUbias', 'imDbias');
    end
end
