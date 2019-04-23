function [results,calibPassed, dfzRegs, dfzTmpRegs] = DFZ_calib(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t)
    fprintff('[-] FOV, System Delay and Zenith calibration...\n');
    if(runParams.DFZ)
    [r,DFZ_regs] = DFZ_calib_Init(hw,fw,runParams,calibParams);

%% save temprature of DFZ calibration: 
        dfzCalTmpStart = Calibration.aux.collectTempData(hw,runParams,fprintff,'Before DFZ calibration:');
%%      capture frame Z and I from 5 secnce for DFZ calibration 
        captures = {calibParams.dfz.captures.capture(:).type};
        trainImages = strcmp('train',captures);
        testImages = ~trainImages;
        nof_frames = 45; %todo take it from calibparams
        path = strings(1,5);
        for i=1:length(captures)
            cap = calibParams.dfz.captures.capture(i);
            targetInfo = targetInfoGenerator(cap.target);
            cap.transformation(1,1) = cap.transformation(1,1)*calibParams.dfz.sphericalScaleFactors(1);
            cap.transformation(2,2) = cap.transformation(2,2)*calibParams.dfz.sphericalScaleFactors(2);
            im(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('DFZ - Image %d',i));
            if ~strcmp('train',cap.type)
                dfzCalTmpEnd = hw.getLddTemperature();
            end
%            im(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('DFZ - Image %d',i),targetInfo);
            InputPath = fullfile(tempdir,'DFZ'); 
            path(i) = fullfile(InputPath,sprintf('Pose%d',i));
            mkdirSafe(path(i));
            fn = fullfile(path(i),'image_params.xml');
            struct2xmlWrapper(targetInfo,fn{1},'image_params');                        % save targetInfo as XML file. 
            Calibration.aux.SaveFramesWrapper(hw, 'ZI' , nof_frames , path(i));  % save images Z and I in sub dir 
        end
        dfzTmpRegs.FRMW.dfzCalTmp = single(dfzCalTmpStart+dfzCalTmpEnd)/2;
        [dfzRegs,results,calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs);
%        [dfzRegs,results,calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs,regs_reff);
%{  
    for use saved images
    else
        InputPath = fullfile(tempdir,'DFZ');
            [dfzRegs,results,calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs);
    end
%}

%%
        DFZ_calib_Output(hw,fw,r,dfzRegs,dfzTmpRegs,calibPassed ,runParams,calibParams);
        
    else
        fprintff('[?] skipped\n');
    end
end
function [] = DFZ_calib_Output(hw,fw,r,dfzRegs,dfzTmpRegs,calibPassed ,runParams,calibParams)
        r.reset();
% { 
        fnCalib = ' ';
        fw.setRegs(dfzRegs,fnCalib);
        fw.setRegs(dfzTmpRegs,fnCalib);
        regs = fw.get(); 
        hw.setReg('DIGGsphericalScale',true);
        hw.shadowUpdate;
%}        
        
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,false);
        end
end

function [r,DFZRegs] = DFZ_calib_Init(hw,fw,runParams,calibParams)
%function [r,DFZRegs,regs_reff] = DFZ_calib_Init(hw,fw,runParams,calibParams)
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,true);
        end
        
        [regs,~]=fw.get();
        regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
        regs.DIGG.sphericalScale = int16(double(regs.DIGG.sphericalScale).*calibParams.dfz.sphericalScaleFactors);

        r=Calibration.RegState(hw);
        
        r.add('JFILinvBypass',true);
        r.add('DESTdepthAsRange',true);
        r.add('DIGGsphericalEn',true);
        r.add('DIGGsphericalScale',regs.DIGG.sphericalScale);

        r.set();
        % prepare list of DFZ registers
        mode = regs.FRMW.mirrorMovmentMode;

        DFZRegs.DESTdepthAsRange    = hw.read('DESTdepthAsRange');
        DFZRegs.DIGGsphericalEn     = hw.read('DIGGsphericalEn');
        DFZRegs.DIGGsphericalScale  = hw.read('DIGGsphericalScale');
        DFZRegs.DESTbaseline        = hw.read('DESTbaseline');
        DFZRegs.DESTbaseline2		= hw.read('DESTbaseline2');
        DFZRegs.GNRLzMaxSubMMExp 	= hw.read('GNRLzMaxSubMMExp');
        DFZRegs.DESTp2axa 			= hw.read('DESTp2axa');
        DFZRegs.DESTp2axb 			= hw.read('DESTp2axb');
        DFZRegs.DESTp2aya 			= hw.read('DESTp2aya');
        DFZRegs.DESTp2ayb 			= hw.read('DESTp2ayb');
        DFZRegs.DIGGsphericalOffset = hw.read('DIGGsphericalOffset');
        DFZRegs.DIGGsphericalScale  = hw.read('DIGGsphericalScale');
        DFZRegs.DESThbaseline       = hw.read('DESThbaseline');
        DFZRegs.DESTtxFRQpd         = hw.read('DESTtxFRQpd');
        DFZRegs.GNRLimgHsize        = hw.read('GNRLimgHsize');
        DFZRegs.GNRLimgVsize        = hw.read('GNRLimgVsize');

        DFZRegs.FRMWmirrorMovmentMode       = regs.FRMW.mirrorMovmentMode; % uint16         (1)
        DFZRegs.FRMWxfov(mode)              = regs.FRMW.xfov(mode);        % single         (65)
        DFZRegs.FRMWyfov(mode)              = regs.FRMW.yfov(mode);        % single         (45)
        DFZRegs.FRMWprojectionYshear(mode)  = regs.FRMW.projectionYshear(mode);  % single   (0)
        DFZRegs.FRMWmarginB 				= regs.FRMW.marginB;           % int16          (0)
        DFZRegs.FRMWmarginL 				= regs.FRMW.marginL;           % int16          (0)
        DFZRegs.FRMWmarginR 				= regs.FRMW.marginR;           % int16          (0)
        DFZRegs.FRMWmarginT 				= regs.FRMW.marginT;           % int16          (0)
        DFZRegs.FRMWlaserangleH             = regs.FRMW.laserangleH;       % single         (0)
        DFZRegs.FRMWlaserangleV 			= regs.FRMW.laserangleV;       % single         (0)
        DFZRegs.FRMWguardBandH              = regs.FRMW.guardBandH;        % single         (0)
        DFZRegs.FRMWguardBandV              = regs.FRMW.guardBandV;        % single         (0)
        DFZRegs.FRMWxres 					= regs.FRMW.xres;              % uint16         (640)
        DFZRegs.FRMWyres 					= regs.FRMW.yres;              % uint16         (360)
        DFZRegs.FRMWpolyVars 				= regs.FRMW.polyVars;          % single x3      [0 0 0]      
        DFZRegs.FRMWyflip                   = regs.FRMW.yflip;             % logical (bool) (0)
        DFZRegs.FRMWxR2L                    = regs.FRMW.xR2L;              % logical (bool) (0)
        DFZRegs.FRMWpitchFixFactor          = regs.FRMW.pitchFixFactor;              % logical (bool) (0)
        DFZRegs.MTLBfastApprox(1)           = regs.MTLB.fastApprox(1);     % logical (bool) (0)
    
%{ 
        % backup from FW regs
        regs_reff.DEST.depthAsRange   = regs.DEST.depthAsRange;
        regs_reff.DIGG.sphericalEn    = regs.DIGG.sphericalEn;
        regs_reff.DIGG.sphericalScale = regs.DIGG.sphericalScale;
        regs_reff.DEST.baseline   	= regs.DEST.baseline;
        regs_reff.DEST.baseline2		= regs.DEST.baseline2;
        regs_reff.GNRL.zMaxSubMMExp 	= regs.GNRL.zMaxSubMMExp;
        regs_reff.DEST.p2axa 			= regs.DEST.p2axa;
        regs_reff.DEST.p2axb 			= regs.DEST.p2axb;
        regs_reff.DEST.p2aya 			= regs.DEST.p2aya;
        regs_reff.DEST.p2ayb 			= regs.DEST.p2ayb;
        regs_reff.DIGG.sphericalOffset(1)= regs.DIGG.sphericalOffset(1);
        regs_reff.DIGG.sphericalOffset(2)= regs.DIGG.sphericalOffset(2);
        regs_reff.DIGG.sphericalScale(1) = regs.DIGG.sphericalScale(1);
        regs_reff.DIGG.sphericalScale(2) = regs.DIGG.sphericalScale(2);
        regs_reff.DEST.hbaseline              = regs.DEST.hbaseline;
        regs_reff.DEST.txFRQpd                = regs.DEST.txFRQpd;
        regs_reff.GNRL.imgHsize               = regs.GNRL.imgHsize;
        regs_reff.GNRL.imgVsize               = regs.GNRL.imgVsize;

        regs_reff.FRMW.mirrorMovmentMode 		= regs.FRMW.mirrorMovmentMode;
        regs_reff.FRMW.xfov(mode) 			= regs.FRMW.xfov(mode);
        regs_reff.FRMW.yfov(mode) 			= regs.FRMW.yfov(mode);
        regs_reff.FRMW.projectionYshear(mode) = regs.FRMW.projectionYshear(mode);
        regs_reff.FRMW.marginB 				= regs.FRMW.marginB;
        regs_reff.FRMW.marginL 				= regs.FRMW.marginL;
        regs_reff.FRMW.laserangleH            = regs.FRMW.laserangleH; 
        regs_reff.FRMW.laserangleV 			= regs.FRMW.laserangleV;
        regs_reff.FRMW.guardBandH 			= regs.FRMW.guardBandH;
        regs_reff.FRMW.guardBandV 			= regs.FRMW.guardBandV;
        regs_reff.FRMW.xres 					= regs.FRMW.xres;
        regs_reff.FRMW.yres 					= regs.FRMW.yres;
        regs_reff.FRMW.polyVars 				= regs.FRMW.polyVars; 
        regs_reff.FRMW.marginL                = regs.FRMW.marginL;
        regs_reff.FRMW.marginR                = regs.FRMW.marginR;
        regs_reff.FRMW.marginT                = regs.FRMW.marginT;
        regs_reff.FRMW.marginB                = regs.FRMW.marginB;
        regs_reff.FRMW.yflip                  = regs.FRMW.yflip;
        regs_reff.FRMW.xR2L                   = regs.FRMW.xR2L; 

        regs_reff.MTLB.fastApprox(1)          = regs.MTLB.fastApprox(1);
%}
        
end
