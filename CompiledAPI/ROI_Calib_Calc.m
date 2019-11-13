function [roiRegs, results, fovData] = ROI_Calib_Calc(frameBytes, calibParams, ROIregs, results, eepromBin)
% description: initiale set of the DSM scale and offset 
%regs_reff
% inputs:
%   frameBytes - images (in bytes sequence form)
%   calibParams - calibparams strcture.
%   ROIregs - list of hw regs values and FW regs
%                                  
% output:
%   dfzRegs - frmw register (fov , polyvars, projectionYshear, laserangleH/V
%   results - geomErr:  and extraImagesGeomErr:
%   calibPassed - pass fail 
%

    t0 = tic;
    global g_output_dir g_calib_dir g_save_input_flag g_save_internal_input_flag g_save_output_flag g_fprintff g_LogFn g_countRuntime;
    
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
        save(fn, 'frameBytes', 'calibParams', 'ROIregs', 'regs', 'results', 'eepromBin');
    end
    
    % operation
    runParams.outputFolder  = output_dir;
    regs                    = ConvertROIReg(ROIregs);
    eepromRegs              = extractEepromRegs(eepromBin, g_calib_dir);
    regs.FRMW.atlMaxAngXL   = eepromRegs.FRMW.atlMaxAngXL;
    regs.FRMW.atlMinAngXR   = eepromRegs.FRMW.atlMinAngXR;
    width                   = regs.GNRL.imgHsize;
    height                  = regs.GNRL.imgVsize;
    im = Calibration.aux.convertBytesToFrames(frameBytes, [height, width], [], false);
    
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn, 'im', 'calibParams', 'regs', 'runParams', 'results', 'fprintff');
    end
    [roiRegs, results, fovData] = ROI_Calib_Calc_int(im, calibParams, regs, runParams, results, fprintff);
    
    % output save
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn, 'roiRegs', 'results', 'fovData');
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

