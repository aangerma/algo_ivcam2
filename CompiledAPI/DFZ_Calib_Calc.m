function [dfzRegs, results, calibPassed] = DFZ_Calib_Calc(frameBytes, calibParams, DFZ_regs)
    % function [dfzRegs,results,calibPassed] = DFZ_Calib_Calc(frameBytes,calibParams,DFZ_regs)
    % description: initiale set of the DSM scale and offset
    %regs_reff
    % inputs:
    %   frameBytes - images from different poses (in bytes sequence form)
    %   calibParams - calibparams strcture.
    %   DFZ_regs - list of hw regs values and FW regs
    %
    % output:
    %   dfzRegs - frmw register (fov , polyvars, projectionYshear, laserangleH/V
    %   results - geomErr:  and extraImagesGeomErr:
    %   calibPassed - pass fail
    %
    t0 = tic;
    global g_output_dir g_save_input_flag  g_save_internal_input_flag  g_save_output_flag  g_fprintff g_calib_dir g_LogFn g_countRuntime; % g_regs g_luts;
    % setting default global value in case not initial in the init function;
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
    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir, func_name,'temp');
    else
        output_dir = g_output_dir;
    end
    
    if(~isempty(g_calib_dir))
        calib_dir = g_calib_dir;
    else
        warning('calib_dir missing in cal_init');
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
    
    % save Input
    regs = ConvertDFZReg(DFZ_regs);
    width = regs.GNRL.imgHsize;
    height = regs.GNRL.imgVsize;
    im = Calibration.aux.convertBytesToFrames(frameBytes, [height,width], [], true);    
    if g_save_input_flag && exist(output_dir,'dir')~=0
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'frameBytes','calibParams' , 'DFZ_regs' );
    end
    if g_save_internal_input_flag && exist(output_dir,'dir')~=0
        fn = fullfile(output_dir, 'mat_files' , [func_name '_int_in.mat']);
        save(fn,'im','output_dir','calibParams', 'fprintff', 'regs');
    end
    [dfzRegs, calibPassed, results] = DFZ_Calib_Calc_int(im, output_dir, calibParams, fprintff, regs);       

    if isfield(DFZ_regs, 'FRMWdfzCalTmp') % DFZ envelope was the one generating these regs, namely we're in Algo1 before Algo 2
        dfzRegs.FRMW.dfzCalTmp          = DFZ_regs.FRMWdfzCalTmp;
        dfzRegs.FRMW.dfzApdCalTmp       = DFZ_regs.FRMWdfzApdCalTmp;
        dfzRegs.FRMW.dfzVbias           = DFZ_regs.FRMWdfzVbias;
        dfzRegs.FRMW.dfzIbias           = DFZ_regs.FRMWdfzIbias;
    end
    dfzRegs.FRMW.fovexExistenceFlag = regs.FRMW.fovexExistenceFlag;
    dfzRegs.FRMW.fovexLensDistFlag  = regs.FRMW.fovexLensDistFlag;
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'dfzRegs', 'calibPassed','results');
    end
    
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\nDFZ_Calib_Calc run time = %.1f[sec]\n', t1);
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function  DFZRegs = ConvertDFZReg(regs)
    DFZRegs.DEST.depthAsRange   	= logical(regs.DESTdepthAsRange);
    DFZRegs.DIGG.sphericalEn    	= logical(regs.DIGGsphericalEn);
    %    DFZRegs.DIGG.sphericalScale 	= typecast(regs.DIGGsphericalScale,'int16');
    temp = typecast(regs.DESTbaseline,'single');
    DFZRegs.DEST.baseline   		= temp(1); %typecast(regs.DESTbaseline,'single');
    DFZRegs.DEST.baseline2			= temp(2); %typecast(regs.DESTbaseline2,'single');
    DFZRegs.GNRL.zMaxSubMMExp       = uint16(regs.GNRLzMaxSubMMExp);
    DFZRegs.DEST.p2axa 				= typecast(regs.DESTp2axa,'single');
    DFZRegs.DEST.p2axb 				= typecast(regs.DESTp2axb,'single');
    DFZRegs.DEST.p2aya 				= typecast(regs.DESTp2aya,'single');
    DFZRegs.DEST.p2ayb 				= typecast(regs.DESTp2ayb,'single');
    DFZRegs.DIGG.sphericalOffset	= typecast(bitand(regs.DIGGsphericalOffset,hex2dec('0fffffff')),'int16');
    DFZRegs.DIGG.sphericalScale 	= typecast(bitand(regs.DIGGsphericalScale ,hex2dec('0fff0fff')),'int16');
    DFZRegs.DEST.hbaseline          = logical(regs.DESThbaseline);
    DFZRegs.DEST.txFRQpd            = typecast(regs.DESTtxFRQpd,'single')'; %x3
    DFZRegs.GNRL.imgHsize           = uint16(regs.GNRLimgHsize);
    DFZRegs.GNRL.imgVsize           = uint16(regs.GNRLimgVsize);
    
    DFZRegs.FRMW.mirrorMovmentMode  = regs.FRMWmirrorMovmentMode;
    DFZRegs.FRMW.xfov 				= regs.FRMWxfov;
    DFZRegs.FRMW.yfov 				= regs.FRMWyfov;
    DFZRegs.FRMW.projectionYshear 	= regs.FRMWprojectionYshear;
    DFZRegs.FRMW.laserangleH       	= regs.FRMWlaserangleH;
    DFZRegs.FRMW.laserangleV 		= regs.FRMWlaserangleV;
    DFZRegs.FRMW.guardBandH         = regs.FRMWguardBandH;
    DFZRegs.FRMW.guardBandV 		= regs.FRMWguardBandV;
    DFZRegs.FRMW.xres 				= regs.FRMWxres;
    DFZRegs.FRMW.yres 				= regs.FRMWyres;
    DFZRegs.FRMW.polyVars 			= regs.FRMWpolyVars; % x3
    DFZRegs.FRMW.marginL            = regs.FRMWmarginL;
    DFZRegs.FRMW.marginR            = regs.FRMWmarginR;
    DFZRegs.FRMW.marginT            = regs.FRMWmarginT;
    DFZRegs.FRMW.marginB            = regs.FRMWmarginB;
    DFZRegs.FRMW.yflip              = regs.FRMWyflip;
    DFZRegs.FRMW.xR2L               = regs.FRMWxR2L; 
    DFZRegs.FRMW.pitchFixFactor     = regs.FRMWpitchFixFactor;              % logical (bool) (0)
   
    DFZRegs.FRMW.undistAngHorz      = regs.FRMWundistAngHorz;
    DFZRegs.FRMW.undistAngVert      = regs.FRMWundistAngVert;
    DFZRegs.FRMW.fovexExistenceFlag = regs.FRMWfovexExistenceFlag;
    DFZRegs.FRMW.fovexNominal       = regs.FRMWfovexNominal;
    DFZRegs.FRMW.fovexLensDistFlag  = regs.FRMWfovexLensDistFlag;
    DFZRegs.FRMW.fovexRadialK       = regs.FRMWfovexRadialK;
    DFZRegs.FRMW.fovexTangentP      = regs.FRMWfovexTangentP;
    DFZRegs.FRMW.fovexCenter        = regs.FRMWfovexCenter;
    DFZRegs.FRMW.rtdOverY           = regs.FRMWrtdOverY;
    DFZRegs.FRMW.rtdOverX           = regs.FRMWrtdOverX;
    DFZRegs.FRMW.saTiltFromEs       = regs.FRMWsaTiltFromEs;
    DFZRegs.FRMW.faTiltFromEs       = regs.FRMWfaTiltFromEs;
        
    % update list
%     DFZRegs.FRMW.dfzCalTmp          = regs.FRMWdfzCalTmp;
%     DFZRegs.FRMW.dfzApdCalTmp       = regs.FRMWdfzApdCalTmp;
%     DFZRegs.FRMW.dfzVbias           = regs.FRMWdfzVbias;
%     DFZRegs.FRMW.dfzIbias           = regs.FRMWdfzIbias;


    DFZRegs.MTLB.fastApprox(1)          	= logical(regs.MTLBfastApprox(1));
end