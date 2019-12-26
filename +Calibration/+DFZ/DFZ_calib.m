function [results,calibPassed, dfzRegs] = DFZ_calib(hw, runParams, calibParams, results, fw,  fprintff, t)
    fprintff('[-] FOV, System Delay and Zenith calibration...\n');
    calibPassed = 1;
    if(runParams.DFZ) 
        
        [r,DFZ_regs] = DFZ_calib_Init(hw,fw,runParams,calibParams,results );

%% save temprature of DFZ calibration: 
        [dfzCalTmpStart,~,~,dfzApdCalTmpStart] = Calibration.aux.collectTempData(hw,runParams,fprintff,'Before DFZ calibration:');
        for j = 1:3
            [pzrsIBiasStart(j),pzrsVBiasStart(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
        end
%%      capture frame Z and I from 5 secnce for DFZ calibration 
        captures = {calibParams.dfz.captures.capture(:).type};
        trainImages = strcmp('train',captures);
        nof_frames = 45; %todo take it from calibparams
        for i=1:length(captures)
            [frameBytes{i},DFZ_regs] = capture1Scene(hw,calibParams,i,trainImages,DFZ_regs,dfzCalTmpStart,dfzApdCalTmpStart,pzrsIBiasStart,pzrsVBiasStart,nof_frames,runParams,results);
        end

        [dfzRegs, dfzresults, calibPassed] = DFZ_Calib_Calc(frameBytes, calibParams, DFZ_regs);
        results.geomErr = dfzresults.geomErr;
        results.extraImagesGeomErr = dfzresults.extraImagesGeomErr;
        results.potentialPitchFixInDegrees = dfzresults.potentialPitchFixInDegrees;
        
        results.dfzScaleErrH = dfzresults.dfzScaleErrH;
        results.dfzScaleErrV = dfzresults.dfzScaleErrV;
        results.dfz3DErrH = dfzresults.dfz3DErrH;
        results.dfz3DErrV = dfzresults.dfz3DErrV;
        results.dfz2DErrH = dfzresults.dfz2DErrH;
        results.dfz2DErrV = dfzresults.dfz2DErrV;
        results.dfzPlaneFit = dfzresults.dfzPlaneFit;
        
        DFZ_calib_Output(hw, fw, r, dfzRegs, results, runParams, calibParams);

        if calibParams.dfz.zenith.useEsTilt && ((DFZ_regs.FRMWsaTiltFromEs==65535) || (DFZ_regs.FRMWfaTiltFromEs==65535))
            fprintff('WARNING: 0xFFFF found in SPOT TILT -> failing DFZ calibration\n');
            calibPassed = 0;
        end
    else
        dfzRegs = struct;
        fprintff('[?] skipped\n');
    end
end
function [frameBytes, DFZ_regs] = capture1Scene(hw,calibParams,i,trainImages,DFZ_regs,dfzCalTmpStart,dfzApdCalTmpStart,pzrsIBiasStart,pzrsVBiasStart,nof_frames,runParams,results)
    cap = calibParams.dfz.captures.capture(i);
    targetInfo = targetInfoGenerator(cap.target); % not saved anywhere
    cap.transformation(1,1) = cap.transformation(1,1)*calibParams.dfz.sphericalScaleFactors(1);
    cap.transformation(2,2) = cap.transformation(2,2)*calibParams.dfz.sphericalScaleFactors(2);
    ii = 0;
    for n=1:numel(calibParams.dfz.captures.capture)
        ii = ii+1;
        nx(n) = ii;
    end
    
    %im(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('DFZ - Image %d',nx(i)));
    Calibration.aux.changeCameraLocation(hw, false, calibParams.robot.dfz.type,calibParams.robot.dfz.dist(i),calibParams.robot.dfz.ang(i),calibParams,hw,1,cap.transformation,sprintf('DFZ - Image %d',nx(i)));
    im(i) = hw.getFrame(45);
    frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZI', nof_frames);
    
end


function [] = DFZ_calib_Output(hw,fw,r,dfzRegs,results ,runParams,calibParams)
        r.reset();

        fnCalib = ' ';
        fw.setRegs(dfzRegs,fnCalib);
        regs = fw.get();
        hw.setReg('DIGGsphericalScale',regs.DIGG.sphericalScale);
        hw.setReg('DIGGsphericalEn',0);
        hw.shadowUpdate;
      
        if hw.getPresetControlState ~= 1 % Move to long range preset
            Calibration.aux.switchPresetAndUpdateModRef( hw,1,calibParams,results );
        end
            
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,false);
        end
end

function [r,DFZRegs] = DFZ_calib_Init(hw,fw,runParams,calibParams,results )
%function [r,DFZRegs,regs_reff] = DFZ_calib_Init(hw,fw,runParams,calibParams)
        Calibration.aux.switchPresetAndUpdateModRef( hw,1,calibParams,results );
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
        saTiltText                  = hw.cmd('ERB 0x4a2 2');
        faTiltText                  = hw.cmd('ERB 0x4a0 2');
        
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
        
        DFZRegs.FRMWundistAngHorz           = regs.FRMW.undistAngHorz;
        DFZRegs.FRMWundistAngVert           = regs.FRMW.undistAngVert;
        if isfield(runParams, 'FOVexInstalled')
            regs.FRMW.fovexExistenceFlag    = runParams.FOVexInstalled;
        end
        DFZRegs.FRMWfovexExistenceFlag      = regs.FRMW.fovexExistenceFlag;
        DFZRegs.FRMWfovexNominal            = regs.FRMW.fovexNominal;
        DFZRegs.FRMWfovexLensDistFlag       = regs.FRMW.fovexLensDistFlag;
        DFZRegs.FRMWfovexRadialK            = regs.FRMW.fovexRadialK;
        DFZRegs.FRMWfovexTangentP           = regs.FRMW.fovexTangentP;
        DFZRegs.FRMWfovexCenter             = regs.FRMW.fovexCenter;
        DFZRegs.FRMWrtdOverY                = regs.FRMW.rtdOverY;
        DFZRegs.FRMWrtdOverX                = regs.FRMW.rtdOverX;
        DFZRegs.FRMWsaTiltFromEs            = single(typecast(uint16(hex2dec(saTiltText([end-1:end, end-4:end-3]))),'int16'))/1e3;
        DFZRegs.FRMWfaTiltFromEs            = single(typecast(uint16(hex2dec(faTiltText([end-1:end, end-4:end-3]))),'int16'))/1e3;
end


function [DFZRegs] = update_DFZRegsList(hw,DFZRegs,dfzCalTmpStart,dfzApdCalTmpStart,pzrsIBiasStart,pzrsVBiasStart, pzrMeasParams)
    [dfzCalTmpEnd,~,~,dfzApdCalTmpEnd] = hw.getLddTemperature();
    for j = 1:3
        [pzrsIBiasEnd(j),pzrsVBiasEnd(j)] = hw.pzrAvPowerGet(j,pzrMeasParams.nVals2avg,pzrMeasParams.sampIntervalMsec);
    end
    DFZRegs.FRMWdfzCalTmp    = single(dfzCalTmpStart+dfzCalTmpEnd)/2;      %double
    DFZRegs.FRMWdfzApdCalTmp = single(dfzApdCalTmpStart+dfzApdCalTmpEnd)/2;%double
    DFZRegs.FRMWdfzVbias     = single(pzrsVBiasStart+pzrsVBiasEnd)/2;      % 1x3 double 
    DFZRegs.FRMWdfzIbias     = single(pzrsIBiasStart+pzrsIBiasEnd)/2;      % 1x3 double
end
