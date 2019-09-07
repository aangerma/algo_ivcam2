function [results,calibPassed, dfzRegs] = DFZ_calib(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t)
    fprintff('[-] FOV, System Delay and Zenith calibration...\n');
    calibPassed = 1;
    if(runParams.DFZ) 
        
        [r,DFZ_regs] = DFZ_calib_Init(hw,fw,runParams,calibParams,results );

%% save temprature of DFZ calibration: 
        [dfzCalTmpStart,~,~,dfzApdCalTmpStart] = Calibration.aux.collectTempData(hw,runParams,fprintff,'Before DFZ calibration:');
        for j = 1:3
            [pzrsIBiasStart(j),pzrsVBiasStart(j)] = hw.pzrPowerGet(j,5);
        end
%%      capture frame Z and I from 5 secnce for DFZ calibration 
        captures = {calibParams.dfz.captures.capture(:).type};
        trainImages = strcmp('train',captures);
        nof_frames = 45; %todo take it from calibparams
        path = cell(1,length(captures));
        for i=1:length(captures)
            [InputPath,DFZ_regs] = capture1Scene(hw,calibParams,i,trainImages,DFZ_regs,dfzCalTmpStart,dfzApdCalTmpStart,pzrsIBiasStart,pzrsVBiasStart,nof_frames,path,runParams,results);
        end
        
        
        [dfzRegs,dfzresults,calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs);
        results.geomErr = dfzresults.geomErr;
        results.extraImagesGeomErr = dfzresults.extraImagesGeomErr;
        results.potentialPitchFixInDegrees = dfzresults.potentialPitchFixInDegrees;
        results.rtdDiffBetweenPresets = dfzresults.rtdDiffBetweenPresets;
        results.shortRangeImagesGeomErr = dfzresults.shortRangeImagesGeomErr;
        
        
        results.dfzScaleErrH = dfzresults.dfzScaleErrH;
        results.dfzScaleErrV = dfzresults.dfzScaleErrV;
        results.dfz3DErrH = dfzresults.dfz3DErrH;
        results.dfz3DErrV = dfzresults.dfz3DErrV;
        results.dfz2DErrH = dfzresults.dfz2DErrH;
        results.dfz2DErrV = dfzresults.dfz2DErrV;
        results.dfzPlaneFit = dfzresults.dfzPlaneFit;
        
        DFZ_calib_Output(hw,fw,r,dfzRegs,results ,runParams,calibParams);
    else
        dfzRegs = struct;
        fprintff('[?] skipped\n');
    end
end
function [InputPath,DFZ_regs] = capture1Scene(hw,calibParams,i,trainImages,DFZ_regs,dfzCalTmpStart,dfzApdCalTmpStart,pzrsIBiasStart,pzrsVBiasStart,nof_frames,path,runParams,results)
    cap = calibParams.dfz.captures.capture(i);
    targetInfo = targetInfoGenerator(cap.target);
    cap.transformation(1,1) = cap.transformation(1,1)*calibParams.dfz.sphericalScaleFactors(1);
    cap.transformation(2,2) = cap.transformation(2,2)*calibParams.dfz.sphericalScaleFactors(2);
    ii = 0;
    for n=1:numel(calibParams.dfz.captures.capture)
        if (~strcmp(calibParams.dfz.captures.capture(n).type,'shortRange'))
            ii = ii+1;
        end
        nx(n) = ii;
    end
    
    if strcmp(cap.type,'shortRange')
        Calibration.aux.switchPresetAndUpdateModRef( hw,2,calibParams,results );
    else
        im(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('DFZ - Image %d',nx(i)));
    end
    
    if ~runParams.afterAlgo2 && (i == find(trainImages,1,'last'))
        DFZ_regs = update_DFZRegsList(hw,DFZ_regs,dfzCalTmpStart,dfzApdCalTmpStart,pzrsIBiasStart,pzrsVBiasStart);
    end
%            im(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('DFZ - Image %d',i),targetInfo);
    InputPath = fullfile(ivcam2tempdir,'DFZ');
    if strcmp(cap.type,'shortRange')
        path{i} = fullfile(InputPath,sprintf('Pose%d_SR',nx(i)));
    else
        path{i} = fullfile(InputPath,sprintf('Pose%d',nx(i)));
    end
    mkdirSafe(path{i});
    fn = fullfile(path{i},'image_params.xml');
    struct2xmlWrapper(targetInfo,fn,'image_params');                        % save targetInfo as XML file. 
    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , nof_frames , path{i});  % save images Z and I in sub dir 
    
    if strcmp(cap.type,'shortRange')
        Calibration.aux.switchPresetAndUpdateModRef( hw,1,calibParams,results );
    end
end
function [modRefDec] = getModRefDecValFromTable(hw,outFolder, presetCsvName)
    presetFn = fullfile(outFolder,'AlgoInternal',presetCsvName);
    presetTable=readtable(presetFn);
    modRefInd=find(strcmp(presetTable.name,'modulation_ref_factor'));
    s=hw.cmd('irb e2 09 01');
    max_hex = sscanf(s,'Address: %*s => %s');
    maxMod_dec = hex2dec(max_hex);
    modRefDec = presetTable.value(modRefInd)*maxMod_dec;
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
        [saTilt, faTilt]        = Calibration.aux.readTiltsFromUnit(hw);
        
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
        DFZRegs.FRMWsaTiltFromEs            = saTilt;
        DFZRegs.FRMWfaTiltFromEs            = faTilt;
end


function [DFZRegs] = update_DFZRegsList(hw,DFZRegs,dfzCalTmpStart,dfzApdCalTmpStart,pzrsIBiasStart,pzrsVBiasStart)
    [dfzCalTmpEnd,~,~,dfzApdCalTmpEnd] = hw.getLddTemperature();
    for j = 1:3
        [pzrsIBiasEnd(j),pzrsVBiasEnd(j)] = hw.pzrPowerGet(j,5);
    end
    DFZRegs.FRMWdfzCalTmp    = single(dfzCalTmpStart+dfzCalTmpEnd)/2;      %double
    DFZRegs.FRMWdfzApdCalTmp = single(dfzApdCalTmpStart+dfzApdCalTmpEnd)/2;%double
    DFZRegs.FRMWdfzVbias     = single(pzrsVBiasStart+pzrsVBiasEnd)/2;      % 1x3 double 
    DFZRegs.FRMWdfzIbias     = single(pzrsIBiasStart+pzrsIBiasEnd)/2;      % 1x3 double
end
