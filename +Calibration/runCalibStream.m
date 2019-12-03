function  [calibPassed] = runCalibStream(runParamsFn,calibParamsFn, fprintff,spark,app)
    t=tic;
    results = struct;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    if(~exist('spark','var'))
        spark=[];
    end
    if(~exist('app','var'))
        app=[];
    end
    % clear calib_temp
    if(exist(ivcam2tempdir,'dir'))
        rmdir(ivcam2tempdir,'s');
    end
    write2spark = ~isempty(spark);
    
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);
    
    if noCalibrations(runParams)
        calibPassed = -1;
        return;
    end
    %% output all RegState to files 
    RegStateSetOutDir(runParams.outputFolder);

    %% Calibration file names
    [runParams,fnCalib] = defineFileNamesAndCreateResultsDir(runParams,calibParams);
    if runParams.afterThermalCalib
        runParams = updateRunParamsForCalibrationAfterThermalCalib(runParams);
    end
    fprintff('Starting calibration:\n');
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f.%1.0f\n','version',runParams.version,runParams.subVersion);
    
    %% Temporary Hack for turn in
    if runParams.replayMode
       calibPassed = 1;
       return;
    end
    %% Load init fw
    fprintff('Loading initial firmware...');
    fw = Pipe.loadFirmware(runParams.internalFolder);
    fw.get();%run autogen
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Load hw interface
    hw = loadHWInterface(runParams,fw,fprintff,t);
    [~,serialNum,~] = hw.getInfo(); 
    fprintff('%-15s %8s\n','serial',serialNum);
    
    
    %% Update init configuration
%     updateInitConfiguration(hw,fw,fnCalib,runParams,calibParams);
    
    %% call HVM_cal_init
	calib_dir = fileparts(fnCalib);
    [calibParams , ~] = HVM_Cal_init(calibParamsFn,calib_dir,fprintff,runParams.outputFolder);

    
    %% Start stream to load the configuration
    Calibration.aux.collectTempData(hw,runParams,fprintff,'Before starting stream:');
    
    %% Init hw configuration
    atlregs = initConfiguration(hw,fw,runParams,calibParams,fprintff,t);

    
    hw.cmd('DIRTYBITBYPASS');
    if ~runParams.afterThermalCalib
        hw.disableAlgoThermalLoop();
    end
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    
    fprintff('Opening stream...');
%     Calibration.aux.startHwStream(hw,runParams);
    hw.startStream(0,runParams.calibRes);
    fprintff('Done(%ds)\n',round(toc(t)));
    fprintff('Set laser to full FOV projection\n');
    hw.cmd('SET_RECTIFIED_PROJECTION 0');
    %% Verify unit's configuration version
   [verValue,verValuefull] = getVersion(hw,runParams);  
    
    %% Set coarse DSM values 
    calibrateCoarseDSM(hw, runParams, calibParams, fprintff,t);
    
    %% Get a frame to see that hwinterface works.
    fprintff('Capturing frame...');
    hw.getFrame();
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Warm up stage
    Calibration.aux.lddWarmUp(hw,app,calibParams,runParams,fprintff);    
    %% Only RGB Calib
    if onlyRGBCalib(runParams)
        results = struct;
        calibPassed = 1;
        calibPassed = calRGB(hw,calibParams,runParams,results,calibPassed,fprintff,fnCalib,t);
        clear hw;
        return
    end
    
    %% ::dsm calib::
    dsmregs = calibrateDSM(hw, fw, runParams, calibParams,results,fnCalib, fprintff,t);
    %% ::calibrate delays::
    [results,calibPassed ,delayRegs] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff);
    if ~calibPassed
        return;
    end
    %% Verify Scan Direction
    [results,calibPassed] = validateScanDirection(hw, results,runParams,calibParams, fprintff);
    if ~calibPassed
      return 
    end
    
    
   %% Validate spherical fill rate
%    [results,calibPassed] = validateCoverage(hw,1, runParams, calibParams,results, fprintff);
%    if ~calibPassed
%        return 
%    end
%    Calibration.aux.collectTempData(hw,runParams,fprintff,'Before los validation:');
%    [results,calibPassed] = validateLos(hw, runParams, calibParams,results, fprintff);
%    if ~calibPassed
%        return
%    end
    %% ::gamma:: 
	results = calibrateDiggGamma(runParams, calibParams, results, fprintff, t);
	calibrateJfilGamma(fw, calibParams,runParams,fnCalib,fprintff);

    %% Calibrate min range preset
    fprintff('Set laser to rectified FOV projection\n');
    hw.cmd('SET_RECTIFIED_PROJECTION 1');
    [results] = calibratePresets(hw, results,runParams,calibParams, fprintff,fw);
    fprintff('Set laser to full FOV projection\n');
    hw.cmd('SET_RECTIFIED_PROJECTION 0');
    
    %% ::DFZ::  Apply DFZ result if passed (It affects next calibration stages)
    
%    [results,calibPassed] = calibrateDFZ(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    [results,calibPassed,dfzRegs] = Calibration.DFZ.DFZ_calib(hw, runParams, calibParams, results, fw, fprintff, t);
    if ~calibPassed
       return 
    end

    %% ::ROI::
    fprintff('Set laser to rectified FOV projection\n');
    hw.cmd('SET_RECTIFIED_PROJECTION 1');
    [results ,roiRegs] = Calibration.roi.ROI_calib(hw, dfzRegs, runParams, calibParams, results,fw, fprintff, t);

    %% Undist and table burn
    eepromRegs = atlregs;
    eepromBin = [];
%    results = END_calib_Calc(verValue, verValuefull ,delayRegs, dsmregs , roiRegs,dfzRegs,results,fnCalib,calibParams,runParams.undist);
    [results,regs,luts] = END_calib_Calc(delayRegs, dsmregs , roiRegs,dfzRegs,results,fnCalib,calibParams,runParams.undist,runParams.configurationFolder, eepromRegs, eepromBin, runParams.afterThermalCalib);

   
    
%     %% Print image final fov
%     [results,calibPassed] = Calibration.aux.calcImFov(fw,results,calibParams,fprintff);
%     if ~calibPassed
%        return 
%     end
    hw.runPresetScript('maReset');
    pause(0.1);
    hw.runScript(fullfile(runParams.outputFolder,'AlgoInternal','postUndistState.txt'));
    pause(0.1);
    hw.runPresetScript('maRestart');
    pause(0.1);
    hw.shadowUpdate();

    try
        %% Validate DFZ before reset
        [results,~] = preResetDFZValidation(hw,fw,results,calibParams,runParams,fprintff);
    catch e
        fprintff('[!] ERROR:%s\n',strtrim(e.message));
        fprintff('CoverageValidation or preResetDFZValidation failed. Skipping...\n');
    end

    %% Burn 2 device
    hw.stopStream;
    burn2Device(hw,1,runParams,calibParams,@fprintf,t);

    %% Create table for rtd over angX fix
    fprintff('Set laser to full FOV projection\n');
    hw.cmd('SET_RECTIFIED_PROJECTION 0');
    Calibration.DFZ.calculateRtdOverAngXFix(hw,runParams,calibParams,regs,luts, fprintff);
    fprintff('Set laser to rectified FOV projection\n');
    hw.cmd('SET_RECTIFIED_PROJECTION 1');
    
    %% Collecting hardware state
    if runParams.saveRegState
        fprintff('Collecting registers state...');
        hw.getRegsFromUnit(fullfile(runParams.outputFolder,'calibrationRegState.txt') ,0 );
        fprintff('Done\n');
    end
    %% Long range calibrations
    if runParams.maxRangePreset
        fprintff('Set laser to rectified FOV projection\n');
        hw.cmd('SET_RECTIFIED_PROJECTION 1');
        resolutions = {calibParams.presets.long.state1.resolution,calibParams.presets.long.state2.resolution};
        for i = 1:2
            res = resolutions{i};
            Calstate = Calibration.presets.findLongRangeStateCal(calibParams,res);
            if(~isempty(res))
                fprintff('Test %s for long range preset, starting stream.\n',Calstate);
                hw = Calibration.aux.resetCamera( hw );
                hw.startStream(0,res);
                results = calibrateLongRangePreset(hw,res,Calstate,results,runParams,calibParams, fprintff);
            end
        end
    end
    presetsTableFullPath = GeneratePresetsTable_Calib_Calc(calibParams);
    fprintff('[-] Burning preset table...');
    try
        hw = HWinterface;
        hw.cmd(['WrCalibInfo ',presetsTableFullPath]);
        fprintff('Done\n');
    catch
        fprintff('failed to burn preset table\n');
    end
    
    if ~calibParams.presets.compare.bypass
        % Calc diff between presets
        hw = Calibration.aux.resetCamera( hw );
        fprintff('Comparing presets per resolution...');
        resolutions = {calibParams.presets.long.state1.resolution,calibParams.presets.long.state2.resolution};
        for i = 1:2
            res = resolutions{i};
            rtd2addRes = Calibration.presets.compareRtdOfShortAndLong(hw,calibParams,res,runParams);
            results = Validation.aux.mergeResultStruct(results, rtd2addRes);
        end
        UpdateShortPresetRtdDiff_Calib_Calc(results);
        presetsTableFullPath = GeneratePresetsTable_Calib_Calc(calibParams);
        
        fprintff('[-] Reburning preset table...');
        try
            hw = HWinterface;
            hw.cmd(['WrCalibInfo ',presetsTableFullPath]);
            fprintff('Done\n');
        catch
            fprintff('failed to burn preset table\n');
        end
    end
    
    
%%
    Calibration.aux.logResults(results,runParams);
    Calibration.aux.writeResults2Spark(results,spark,calibParams.errRange,write2spark,'Cal');
    calibPassed = Calibration.aux.mergeScores(results,calibParams.errRange,fprintff,0);
    
    fprintff('[!] calibration ended - ');
    if(calibPassed==0)
        fprintff('FAILED.\n');
        fprintff('Reburning initial tables...');
        fw = Pipe.loadFirmware(fullfile(fileparts(mfilename('fullpath')),runParams.configurationFolder));
        fw.get();%run autogen
         %% Init hw configuration
        runParams.init = 1;
        initConfiguration(hw,fw,runParams,calibParams,fprintff,t);
    else
        fprintff('PASSED.\n');
    end
    fprintff('Calibration finished(%d)\n',round(toc(t)));
    

    %% rgb calibration
    if calibPassed
        calibPassed = calRGB(hw,calibParams,runParams,results,calibPassed,fprintff,fnCalib,t);
        if runParams.post_calib_validation
            hw.stopStream;
            hw.cmd('rst');
            pause(10);
        end
    end
    clear hw;
end
function updateShortRangeRtdOffset(results,runParams)
    shortRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','shortRangePreset.csv');
    shortRangePreset=readtable(shortRangePresetFn);
    AlgoThermalLoopOffsetInd=find(strcmp(shortRangePreset.name,'AlgoThermalLoopOffset'));
    shortRangePreset.value(AlgoThermalLoopOffsetInd) = shortRangePreset.value(AlgoThermalLoopOffsetInd) + mean([results.rtd2add2short_state1,results.rtd2add2short_state2]);
    writetable(shortRangePreset,shortRangePresetFn);
    
end
function updateLongRangeRtdOffset(results,runParams)
    longRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','longRangePreset.csv');
    longRangePreset=readtable(longRangePresetFn);
    AlgoThermalLoopOffsetInd=find(strcmp(longRangePreset.name,'AlgoThermalLoopOffset'));
    longRangePreset.value(AlgoThermalLoopOffsetInd) = mean([results.rtdDiffViaLaserPower_state1,results.rtdDiffViaLaserPower_state2]);
    writetable(longRangePreset,longRangePresetFn);
end
function results = findRtdDiffFromLP(hw,results,runParams,calibParams,Calstate,fprintff)
r=Calibration.RegState(hw);
r.add('JFILinvBypass',true);
r.add('DESTdepthAsRange',true);
r.add('DESTbaseline$',single(0));
r.add('DESTbaseline2$',single(0));
r.set();

s=hw.cmd('irb e2 09 01');
max_hex = sscanf(s,'Address: %*s => %s');
maxMod_dec = hex2dec(max_hex);
scale = results.(['maxRangeScaleModRef_',Calstate]);
chosenModRef = dec2hex(round(scale*maxMod_dec));    
cmdstr = sprintf('iwb e2 0a 01 %s',chosenModRef);
cmdstrMax = sprintf('iwb e2 0a 01 %s',max_hex);
hw.cmd(cmdstr);
pause(5);
frameLow = hw.getFrame(30);
hw.cmd(cmdstrMax);
pause(5);
frameMax = hw.getFrame(30);

params = Validation.aux.defaultMetricsParams();
params.mask.rectROI.flag = true;
params.mask.rectROI.allMargins = calibParams.presets.compare.roi;
sz = size(frameMax(1).i);
mask = Validation.aux.getMask(params,'imageSize',sz);
results.(['rtdDiffViaLaserPower_',Calstate]) = mean(frameMax.z(mask)/4*2) - mean(frameLow.z(mask)/4*2);
    
r.reset();
end
function calibPassed = calRGB(hw,calibParams,runParams,results,calibPassed,fprintff,fnCalib,t)
    if runParams.rgb && ~runParams.replayMode
        fprintff('[-] Reseting before RGB calibration... '); 
%         hw.saveRecData();
        hw.cmd('rst');
        pause(10);
        clear hw;
        pause(1);
        hw = HWinterface;
        fprintff('Done \n');
        hw.cmd('DIRTYBITBYPASS');
        Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
        %% set preset to min range: Gain control=2
%         fprintff('Set preset to max range.\n');
%         hw.setPresetControlState(1);  
        Calibration.aux.startHwStream(hw,runParams);
        hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
        hw.shadowUpdate;
        Calibration.aux.collectTempData(hw,runParams,fprintff,'Before rgb calibration:');
        [results,rgbTable,rgbPassed] = Calibration.rgb.calibrateRGB(hw, runParams, calibParams, results,fnCalib, fprintff, t);
        if rgbPassed
            rgbTableFileName = Calibration.aux.genTableBinFileName('RGB_Calibration_Info_CalibInfo', rgbTable.version);
            rgbTableFullPath = fullfile(runParams.outputFolder, rgbTableFileName);
            writeAllBytes(rgbTable.data,rgbTableFullPath);
            try
                hw.cmd(sprintf('WrCalibInfo "%s"',rgbTableFullPath));
            catch
                fprintff('Failed to write RGB calibration table. Check if EEPROM TOC supports RGB.\n');
            end
        end
        rgbResults.rgbIntReprojRms = results.rgbIntReprojRms;
        rgbResults.rgbExtReprojRms = results.rgbExtReprojRms;
        rgbResults.lineFitRmsErrHor2dRGB = results.lineFitRmsErrHor2dRGB;
        rgbResults.lineFitRmsErrVer2dRGB = results.lineFitRmsErrVer2dRGB;
        rgbResults.lineFitMaxRmsErrHor2dRGB = results.lineFitMaxRmsErrHor2dRGB;
        rgbResults.lineFitMaxRmsErrVer2dRGB = results.lineFitMaxRmsErrVer2dRGB;
        rgbResults.lineFitMaxErrHor2dRGB = results.lineFitMaxErrHor2dRGB;
        rgbResults.lineFitMaxErrVer2dRGB = results.lineFitMaxErrVer2dRGB;
        rgbResults.uvMapMeanRmse = results.uvMapMeanRmse;
        rgbResults.uvMapMaxErr = results.uvMapMaxErr;
        rgbResults.uvMapMaxErr95 = results.uvMapMaxErr95;
        %% merge all scores outputs
        rgbCalibPassed = Calibration.aux.mergeScores(rgbResults,calibParams.errRange,fprintff);
        calibPassed = calibPassed && rgbCalibPassed;
    end
end
function [results,calibPassed] = preResetDFZValidation(hw,fw,results,calibParams,runParams,fprintff)
    % Compare the geometric error between spherical image and regular image
    calibPassed = 1;
    if runParams.pre_calib_validation
        hw.setReg('JFILinvBypass',true);
        hw.shadowUpdate;
        regs=fw.get();
        frames = Calibration.aux.CBTools.showImageRequestDialog(hw,1,calibParams.dfz.preResetCapture.capture.transformation,'DFZ pre reset validation image');
        Calibration.aux.collectTempData(hw,runParams,fprintff,'DFZ validation before reset:');
        regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
        regs.DIGG.sphericalScale = int16(double(regs.DIGG.sphericalScale).*calibParams.dfz.sphericalScaleFactors);
        r=Calibration.RegState(hw);
        r.add('JFILinvBypass',true);
        r.add('DESTdepthAsRange',true);
        r.add('DIGGsphericalEn',true);
        r.add('DIGGsphericalScale',regs.DIGG.sphericalScale);
        
        r.set();
        pause(0.1);
        framesSpherical = hw.getFrame(45);
        
        fn = fullfile(runParams.outputFolder, 'mat_files' , 'preResetDFZValidation_in.mat');
        save(fn,'frames','framesSpherical', 'regs' , 'calibParams' , 'runParams');    
        
        [dfzRes,~ ] = Calibration.validation.validateDFZ( hw,frames,@sprintf,calibParams,runParams);
        if calibParams.dfz.sampleRTDFromWhiteCheckers
            results.eGeomSphericalDis = dfzRes.GeometricErrorWht;
        else
            results.eGeomSphericalDis = dfzRes.GeometricErrorReg;
        end
        targetInfo = targetInfoGenerator('Iv2A1');
        targetInfo.cornersX = 20;
        targetInfo.cornersY = 28;
        CB = CBTools.Checkerboard (framesSpherical.i, 'targetType', 'checkerboard_Iv2A1','imageRotatedBy180',true);  
        pts = CB.getGridPointsMat;
        grid = [size(pts,1),size(pts,2),1];
        framesSpherical.pts = pts;
        framesSpherical.grid = grid;
        framesSpherical.pts3d = create3DCorners(targetInfo)';
        framesSpherical.rpt = Calibration.aux.samplePointsRtd(framesSpherical.z,pts,regs);
        if exist(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat'), 'file') == 2
            load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); % loads undistTpsModel
        else
            tpsUndistModel = [];
        end
        calibParams.dfz.calibrateOnCropped = 0;
        calibParams.dfz.zenith.useEsTilt = 0;
        [~,dfzResults] = Calibration.aux.calibDFZ(framesSpherical,regs,calibParams,fprintff,[],runParams,tpsUndistModel);
        results.eGeomSphericalEn = dfzResults.geomErr;
        r.reset();
%         hw.setReg('DIGGsphericalScale',[640,480]);
        hw.shadowUpdate;
        
        
        calibPassed = (results.eGeomSphericalDis < calibParams.errRange.eGeomSphericalDis(2)) && (results.eGeomSphericalEn<calibParams.errRange.eGeomSphericalEn(2));
        if calibPassed
            fprintff('[v] DFZ pre reset validation passed[eReg=%.2g,eSp=%.2g]\n',results.eGeomSphericalDis,results.eGeomSphericalEn);
        else
            fprintff('[x] DFZ pre reset validation failed[eReg=%.2g,eSp=%.2g]\n',results.eGeomSphericalDis,results.eGeomSphericalEn);
        end
        
    end
    

end
function [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn)
    runParams=xml2structWrapper(runParamsFn);
    %backward compatibility
    if(~isfield(runParams,'uniformProjectionDFZ'))
        runParams.uniformProjectionDFZ=true;
    end
   
    if(~exist('calibParamsFn','var') || isempty(calibParamsFn))
        %% ::load default caliration configuration
        calibParamsFn='calibParams360p.xml';
    end
    calibParams = xml2structWrapper(calibParamsFn);
    
end
function [runParams,fnCalib,fnUndsitLut] = defineFileNamesAndCreateResultsDir(runParams,calibParams)
    runParams.internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');
    mkdirSafe(runParams.outputFolder);
    mkdirSafe(runParams.internalFolder);
    fnCalib     = fullfile(runParams.internalFolder,'calib.csv');
    fnUndsitLut = fullfile(runParams.internalFolder,'FRMWundistModel.bin32');
    initFldr = fullfile(fileparts(mfilename('fullpath')),runParams.configurationFolder);
    initPresetsFolder = fullfile(fileparts(mfilename('fullpath')),'+presets',['+',runParams.presetsDefFolder]);
    eepromStructureFn = fullfile(fileparts(mfilename('fullpath')),'eepromStructure');
    copyfile(fullfile(initFldr,'*.csv'),  runParams.internalFolder);
    copyfile(fullfile(initPresetsFolder,'*.csv'),  runParams.internalFolder);
    copyfile(fullfile(ivcam2root ,'+Pipe' ,'tables','*.frmw'), runParams.internalFolder);
    copyfile(fullfile(runParams.internalFolder ,'*.frmw'), fullfile(ivcam2root,'CompiledAPI','calib_dir'));
    copyfile(fullfile(runParams.internalFolder ,'*.csv'), fullfile(ivcam2root,'CompiledAPI','calib_dir'));
%     struct2xmlWrapper(calibParams,fullfile(runParams.outputFolder,'calibParams.xml'));
    copyfile(fullfile(eepromStructureFn,'*.csv'),  runParams.internalFolder);
    copyfile(fullfile(eepromStructureFn,'*.mat'),  runParams.internalFolder);
    copyfile(fullfile(eepromStructureFn,'*.mat'),  fullfile(ivcam2root,'CompiledAPI','calib_dir'));
    copyfile(fullfile(eepromStructureFn,'*.csv'),  fullfile(ivcam2root,'CompiledAPI','calib_dir'));
end

function hw = loadHWInterface(runParams,fw,fprintff,t)
    fprintff('Loading HW interface...');
    if isfield(runParams,'replayFile')
        hwRecFile = runParams.replayFile;
    else
        hwRecFile = [];
    end
    
    if runParams.replayMode
        if(exist(hwRecFile,'file'))
            % Use recorded session
            hw=HWinterfaceFile(hwRecFile);
            fprintff('Loading recorded capture(%s)\n',hwRecFile);
            
        else
            error('no file found in %s\n',hwRecFile)
        end
    else
        hw=HWinterface(fw,fullfile(runParams.outputFolder,'sessionRecord.mat'));
        
    end
    fprintff('Done(%ds)\n',round(toc(t)));
end

function [verValue,versionFull] = getVersion(hw,runParams)
    verValue = typecast(uint8([round(100*mod(runParams.version,1)) floor(runParams.version) 0 0]),'uint32');
    
    unitConfigVersion=hw.read('DIGGspare_005');
    if(unitConfigVersion~=verValue)
        warning('incompatible configuration versions!');
    end
    versionFull = typecast(uint8([runParams.subVersion round(100*mod(runParams.version,1)) floor(runParams.version) 0]),'uint32');
end
% function updateInitConfiguration(hw,fw,fnCalib,runParams,calibParams)
%     if ~runParams.DSM
%         currregs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
%         currregs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
%         currregs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
%         currregs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single'); 
%     end
%     if ~runParams.dataDelay
%         currregs.EXTL.conLocDelaySlow = hw.read('EXTLconLocDelaySlow');
%         currregs.EXTL.conLocDelayFastC = hw.read('EXTLconLocDelayFastC');
%         currregs.EXTL.conLocDelayFastF = hw.read('EXTLconLocDelayFastF');
%     end
%     if ~runParams.DFZ
%         DIGGspare = hw.read('DIGGspare');
%         currregs.FRMW.xfov = repmat(typecast(DIGGspare(2),'single'),1,5);
%         currregs.FRMW.yfov = repmat(typecast(DIGGspare(3),'single'),1,5);
%         currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
%         currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
%         currregs.DEST.txFRQpd = typecast(hw.read('DESTtxFRQpd'),'single')';
%     
%         
%         JFILspare = hw.read('JFILspare');
%         currregs.FRMW.pitchFixFactor = typecast(JFILspare(3),'single');
%         currregs.FRMW.polyVars = typecast(JFILspare(4:6),'single');
%         currregs.FRMW.dfzCalTmp = typecast(JFILspare(2),'single');
%         currregs.FRMW.dfzApdCalTmp = typecast(JFILspare(7),'single');
%         DCORspare = hw.read('DCORspare');
%         currregs.FRMW.dfzVbias = typecast(DCORspare(3:5),'single');
%         currregs.FRMW.dfzIbias = typecast(DCORspare(6:8),'single');
%     end
%     if ~runParams.ROI
%         DIGGspare06 = hw.read('DIGGspare_006');
%         DIGGspare07 = hw.read('DIGGspare_007');
%         currregs.FRMW.calMarginL = typecast(uint16(bitshift(DIGGspare06,-16)),'int16');
%         currregs.FRMW.calMarginR = typecast(uint16(mod(DIGGspare06,2^16)),'int16');
%         currregs.FRMW.calMarginT = typecast(uint16(bitshift(DIGGspare07,-16)),'int16');
%         currregs.FRMW.calMarginB = typecast(uint16(mod(DIGGspare07,2^16)),'int16');
%     end
% %     currregs.GNRL.imgHsize = uint16(calibParams.gnrl.internalImSize(2));
% %     currregs.GNRL.imgVsize = uint16(calibParams.gnrl.internalImSize(1));
% %     currregs.FRMW.calImgHsize = currregs.GNRL.imgHsize;
% %     currregs.FRMW.calImgVsize = currregs.GNRL.imgVsize;
% %     currregs.FRMW.externalVsize = uint32(calibParams.gnrl.externalImSize(1));
% %     currregs.FRMW.externalHsize = uint32(calibParams.gnrl.externalImSize(2));
% % 
% %     [~,~,isId] = hw.getInfo();
% %     currregs.DEST.hbaseline = ~isId;
% %     if currregs.DEST.hbaseline
% %         currregs.DEST.baseline = single(calibParams.dest.hBaseline);
% %     else
% %         currregs.DEST.baseline = single(calibParams.dest.vBaseline);
% %     end
% %     currregs.GNRL.zMaxSubMMExp = uint16(log(calibParams.gnrl.zNorm)/log(2));
% %     currregs.JFIL.invMinMax = uint16([calibParams.gnrl.minRange*calibParams.gnrl.zNorm,intmax('uint16')]);
%     if(exist('currregs','var'))
%         fw.setRegs(currregs,fnCalib);
%         fw.get();
%     end
%     
%     
% end
function atlregs = initConfiguration(hw,fw,runParams,calibParams,fprintff,t)  
    fprintff('init hw configuration...');
    atlregs = struct;
    if(runParams.init)
        eRegs = hw.readAlgoEEPROMtable();
        if ~runParams.dataDelay
            vregs.EXTL.conLocDelaySlow = eRegs.EXTL.conLocDelaySlow;
            vregs.EXTL.conLocDelayFastC = eRegs.EXTL.conLocDelayFastC;
            vregs.EXTL.conLocDelayFastF = eRegs.EXTL.conLocDelayFastF;
        end
        fprintff('[-] Burning default config calib files...');
        vers = calibToolVersion;
        vregs.FRMW.calibVersion = uint32(hex2dec(single2hex(vers)));
        vregs.FRMW.configVersion = uint32(hex2dec(single2hex(vers)));
        if runParams.afterThermalCalib
            atlregs.FRMW.atlMinVbias1 = eRegs.FRMW.atlMinVbias1;
            atlregs.FRMW.atlMaxVbias1 = eRegs.FRMW.atlMaxVbias1;
            atlregs.FRMW.atlMinVbias2 = eRegs.FRMW.atlMinVbias2;
            atlregs.FRMW.atlMaxVbias2 = eRegs.FRMW.atlMaxVbias2;
            atlregs.FRMW.atlMinVbias3 = eRegs.FRMW.atlMinVbias3;
            atlregs.FRMW.atlMaxVbias3 = eRegs.FRMW.atlMaxVbias3;
        end
        fw.setRegs(vregs,'');
        fw.setRegs(atlregs,'');
        fw.generateTablesForFw(fullfile(runParams.internalFolder,'initialCalibFiles'),0,runParams.afterThermalCalib, calibParams.tableVersions);
        rtdOverXTableFileName = Calibration.aux.genTableBinFileName('Algo_rtdOverAngX_CalibInfo', calibParams.tableVersions.algoRtdOverAngX);
        fw.writeRtdOverAngXTable(fullfile(runParams.internalFolder,'initialCalibFiles', rtdOverXTableFileName),[]);
        if ~runParams.afterThermalCalib
            presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', calibParams.tableVersions.dynamicRange);
            fw.writeDynamicRangeTable(fullfile(runParams.internalFolder,'initialCalibFiles', presetsTableFileName));
        end
        hw.burnCalibConfigFiles(fullfile(runParams.internalFolder,'initialCalibFiles'));
        hw.cmd('rst');
        pause(10);
        fprintff('Done\n');
    else
        fprintff('skipped\n');
        txDelay = typecast(hw.read('DESTtxFRQpd_000'),'single');
        txDelayRef = fw.getAddrData('DESTtxFRQpd_000');
        txDelayRef = typecast(txDelayRef{2},'single');
        if abs(txDelay-txDelayRef)>0.5
           fprintff('WARNING: Calibration should be done with default EEPROM or with init stage checked!\n'); 
        end

    end
end
function [results,calibPassed , delayRegs] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff)
    calibPassed = 1;
    fprintff('[-] Depth and IR delay calibration...\n');
    if(runParams.dataDelay)
        Calibration.dataDelay.setAbsDelay(hw,calibParams.dataDelay.fastDelayInitVal,calibParams.dataDelay.slowDelayInitVal);
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]),'Delay Calibration',1);
        Calibration.aux.collectTempData(hw,runParams,fprintff,'Before delays calibration:');
        [delayRegs,delayCalibResults]=Calibration.dataDelay.calibrate(hw, calibParams.dataDelay, fprintff, runParams, calibParams, false);
        
        fw.setRegs(delayRegs,fnCalib);
        
        results.delayS = (1- delayCalibResults.slowDelayCalibSuccess);
        results.delaySlowPixelVar = delayCalibResults.delaySlowPixelVar;
        results.delayF = (1-delayCalibResults.fastDelayCalibSuccess);
        
        if delayCalibResults.slowDelayCalibSuccess 
            fprintff('[v] ir delay calib passed [e=%g]\n',results.delayS);
        else
            fprintff('[x] ir delay calib failed [e=%g]\n',results.delayS);
            calibPassed = 0;
        end
        
        pixVarRange = calibParams.errRange.delaySlowPixelVar;
        if  results.delaySlowPixelVar >= pixVarRange(1) &&...
                results.delaySlowPixelVar <= pixVarRange(2)
            fprintff('[v] ir vertical pixel alignment variance [e=%g]\n',results.delaySlowPixelVar);
        else
            fprintff('[x] ir vertical pixel alignment variance [e=%g]\n',results.delaySlowPixelVar);
            calibPassed = 0;
        end
        
        if delayCalibResults.fastDelayCalibSuccess
            fprintff('[v] depth delay calib passed [e=%g]\n',results.delayF);
        else
            fprintff('[x] depth delay calib failed [e=%g]\n',results.delayF);
            calibPassed = 0;
        end
        
    else
        eepromregs = hw.readAlgoEEPROMtable();
        currregs.EXTL.conLocDelaySlow = eepromregs.EXTL.conLocDelaySlow;
        currregs.EXTL.conLocDelayFastC = eepromregs.EXTL.conLocDelayFastC;
        currregs.EXTL.conLocDelayFastF = eepromregs.EXTL.conLocDelayFastF;
        delayRegs = currregs;
        fprintff('skipped\n');
    end
    
end

function [calibParams , ret] = HVM_Cal_init(fn_calibParams,calib_dir,fprintff,output_dir)
    if(~exist('output_dir','var'))
        output_dir = fullfile(tempdir,'\cal_tester\output');
    end
    debug_log_f         = 0;
    verbose             = 0;
    save_input_flag     = 1;
    save_output_flag    = 1;
    dummy_output_flag   = 0;
    ret = 1;
    [calibParams ,~] = cal_init(output_dir,calib_dir,fn_calibParams, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag,fprintff);
end


function calibrateCoarseDSM(hw, runParams, calibParams, fprintff, t)
    % Set a DSM value that makes the valid area of the image in spherical
    % mode to be above a certain threshold.
    fprintff('[-] Coarse DSM calibration...\n');
    if(runParams.DSM)
        Calibration.DSM.DSM_CoarseCalib(hw,calibParams,runParams);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
end

function [results,calibPassed] = validateLos(hw, runParams, calibParams, results, fprintff)
    calibPassed = 1;
    if runParams.validateLOS
        %test coverage
        [losResults] = Calibration.validation.validateLOS(hw,runParams,[],calibParams.gnrl.cbPtsSz,fprintff);
        if ~isempty(fieldnames(losResults))
            metrics = {'losMaxP2p','losMeanStdX','losMeanStdY'};
            for m=1:length(metrics)
                results.(metrics{m}) = losResults.(metrics{m});
                metricPassed = losResults.(metrics{m}) <= calibParams.errRange.(metrics{m})(2) && ...
                    losResults.(metrics{m}) >= calibParams.errRange.(metrics{m})(1);
                calibPassed = calibPassed & metricPassed;
            end
            if calibPassed
                fprintff('[v] los max peak to peak passed[e=%g]\n',losResults.losMaxP2p);
            else
                fprintff('[x] los max peak to peak failed[e=%g]\n',losResults.losMaxP2p);
            end
        else
            calibPassed = false;
            fprintff('[x] los metric finished with error\n',[]);
        end
    end
    
end
function [results] = calibratePresets(hw, results,runParams,calibParams, fprintff,fw)
%% calibrate min range
    results = calibrateMinRangePreset(hw, results,runParams,calibParams, fprintff);
%% switch presets
%     hw.stopStream(); 
%     fprintff('Switch to long range preset\n');
%     % set preset to max range: Gain control=1
%     hw.setPresetControlState(1);   
%     hw.startStream(0,runParams.calibRes);

%% calibrate max range
%     results = calibrateLongRangePreset(hw, results,runParams,calibParams, fprintff);

%% burn presets
%    burnPresets(hw,runParams,calibParams, fprintff,fw);
    hw.setPresetControlState(1);   
end
function [results] = calibrateMinRangePreset(hw, results,runParams,calibParams, fprintff)
    if runParams.minRangePreset
        fprintff('[-] Calibrating short range laser power...\n');
        Calibration.aux.switchPresetAndUpdateModRef( hw,2,calibParams,results );
        hw.setReg('JFILgammaScale',int16([hex2dec('400'),hex2dec('400')]));
        hw.setReg('JFILgammaShift',uint32(0));
        hw.shadowUpdate;
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.006 .0006 1]),'Short Range Calibration - 20c"m');
        [results.minRangeScaleModRef,results.maxModRefDec] = Calibration.presets.calibrateMinRange(hw,calibParams,runParams,fprintff);
        Calibration.aux.switchPresetAndUpdateModRef( hw,1,calibParams,results );
    end
end

function [results] = calibrateLongRangePreset(hw,resolution,state,results,runParams,calibParams, fprintff)
    if runParams.maxRangePreset
        fprintff(['[-] Calibrating long range laser power on ',mat2str(resolution),' resolution ...\n']);
        Calibration.aux.switchPresetAndUpdateModRef( hw,1,calibParams,results );
        % run on calib Res
        [results.(['maxRangeScaleModRef_',state]),maxModRefDec,results.(['maxFillRate_',state]),...
         results.(['targetDist_',state])] = Calibration.presets.calibrateLongRange(hw,calibParams,state,runParams,fprintff);

        
        %% Set laser val
        tmpres.maxRangeScaleModRef=results.(['maxRangeScaleModRef_',state]); 
        tmpres.maxModRefDec=maxModRefDec;
        Calibration.aux.switchPresetAndUpdateModRef( hw,1,calibParams,tmpres );
    end
end

function [results,calibPassed] = validateScanDirection(hw, results,runParams,calibParams, fprintff)
    calibPassed = 1;
    fprintff('[-] Validating scan direction...\n');
    if runParams.scanDir
        frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]),'Scan Direction Validation');
        IR = frame.i;

        [ isLeft, isTop ] = Calibration.aux.CBTools.detectCBOrientation(IR,runParams);      
        if ~isLeft
           hDirStr = 'Left2Right';
        else
           hDirStr = 'Right2Left'; 
        end
        if isTop
           vDirStr = 'Top2Bottom';
        else
           vDirStr = 'Bottom2Top'; 
        end
 
        fprintff('Scan direction is: %s & %s\n',hDirStr,vDirStr);

        % For L515, the scan direction makes it so the gray circle is *below* and to the left of the black circle
        % For L520, the scan direction makes it so the gray circle is *above* and to the left of the black circle
        if calibParams.scanDir.stickerLocationIsLeft
            calibPassed = ~isLeft;
        else
            calibPassed = isLeft;
        end    
        if calibParams.scanDir.stickerLocationIsTop
            calibPassed = calibPassed && ~isTop;
        else
            calibPassed = calibPassed && isTop;
        end
             
        if ~calibPassed
            fprintff('[x] Scan direction validation failed\n');
        end
    else
        fprintff('[?] skipped\n');
    end
end

function [results,calibPassed] = validateCoverage(hw,sphericalEn, runParams, calibParams, results, fprintff)
    calibPassed = 1;
    if runParams.pre_calib_validation
        if sphericalEn 
            sphericalmode = 'Spherical Enable';
            fname = strcat('irCoverage','SpEn');
            fnameStd = strcat('stdIrCoverage','SpEn');
        else
            sphericalmode = 'spherical disable';
            fname = strcat('irCoverage','SpDis');
            fnameStd = strcat('stdIrCoverage','SpDis');
        end
        
        %test coverage
        [~, covResults,dbg] = Calibration.validation.validateCoverage(hw,sphericalEn);
        % save prob figure
        ff = Calibration.aux.invisibleFigure;
        imagesc(dbg.probIm);
        
        title(sprintf('Coverage Map %s',sphericalmode)); colormap jet;colorbar;
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',sprintf('Coverage Map %s',sphericalmode));

        ff = Calibration.aux.invisibleFigure;
        plot(dbg.probImV');
        
        title(sprintf('Coverage %s per horizontal slice',sphericalmode));legend('1-H','2','3-C','4','5-L');xlim([0 size(dbg.probIm,2)]);
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',sprintf('Coverage %s per horizontal slice',sphericalmode));
        
        calibPassed = covResults.irCoverage <= calibParams.errRange.(fname)(2) && ...
            covResults.irCoverage >= calibParams.errRange.(fname)(1);
        
        
        if calibPassed
            fprintff('[v] ir coverage %s passed[e=%g]\n',sphericalmode,covResults.irCoverage);
        else
            fprintff('[x] ir coverage %s failed[e=%g]\n',sphericalmode,covResults.irCoverage);
        end
        if sphericalEn
            results.(fname) = covResults.irCoverage;
            results.(fnameStd) = covResults.stdIrCoverage; 
        else
            results.(fname) = covResults.irCoverage;
            results.(fnameStd) = covResults.stdIrCoverage; 
        end
    end
end
function [dsmregs] = calibrateDSM(hw,fw, runParams, calibParams,results, fnCalib, fprintff, t)

    fprintff('[-] DSM calibration...\n');
    if(runParams.DSM)
        dsmregs = Calibration.DSM.DSM_Calib(hw,fprintff,calibParams,runParams);
        fw.setRegs(dsmregs,fnCalib);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        dsmregs = struct;
        fprintff('[?] skipped\n');
    end
    
end

function calibrateJfilGamma(fw, calibParams,runParams,fnCalib,fprintff)
    fprintff('[-] Jfil gamma...\n');
    if (runParams.gamma)
        irInnerRange = calibParams.gnrl.irInnerRange;
        irOuterRange = calibParams.gnrl.irOuterRange;
        regs = fw.get();
        newGammaScale = int16([regs.JFIL.gammaScale(1),diff(irOuterRange)/diff(irInnerRange)*1024]);
        newGammaShift = int16([regs.JFIL.gammaShift(1),irOuterRange(1) - newGammaScale(2)*irInnerRange(1)/1024]);
        gammaRegs.JFIL.gammaScale = newGammaScale;
        gammaRegs.JFIL.gammaShift = newGammaShift;
        fw.setRegs(gammaRegs,fnCalib);
        fprintff('[v] Done\n');
    else
        fprintff('[?] skipped\n');
    end

end

function results = calibrateDiggGamma(runParams, calibParams, results, fprintff, t)
    fprintff('[-] Digg gamma...\n');
    if (runParams.gamma)
        %     [gammaregs,results.gammaErr] = Calibration.aux.runGammaCalib(hw,.verbose);
        %
        %     if(results.gammaErr,calibParams.errRange.gammaErr(2))
        %         fprintff('[v] gamma passed[e=%g]\n',results.gammaErr);
        %     else
        %         fprintff('[x] gamma failed[e=%g]\n',results.gammaErr);
        %         score = 0;
        %         return;
        %     end
        %     fw.setRegs(gammaregs,fnCalib);
        results.gammaErr=0;
        fprintff('[v] Done(%ds)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
end
function [results,calibPassed,dfzRegs,dfzTmpRegs] = calibrateDFZ(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t)
        [results,calibPassed,dfzRegs,dfzTmpRegs] = Calibration.DFZ.DFZ_calib(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t);
%        [results,calibPassed] = calibrateDFZ_backup(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t);
end
function [results,calibPassed] = calibrateDFZ_backup(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t)
    calibPassed = 1;
    fprintff('[-] FOV, System Delay and Zenith calibration...\n');
    if(runParams.DFZ)
        calibPassed = 0;
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,true);
        end
        [regs,luts]=fw.get();
        
        regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
        regs.DIGG.sphericalScale = int16(double(regs.DIGG.sphericalScale).*calibParams.dfz.sphericalScaleFactors);
    
        r=Calibration.RegState(hw);
        
        r.add('JFILinvBypass',true);
        r.add('DESTdepthAsRange',true);
        r.add('DIGGsphericalEn',true);
        r.add('DIGGsphericalScale',regs.DIGG.sphericalScale);

        r.set();
        
        
        frame = hw.getFrame(10);
        bwIm = frame.i>0;
        %{
        imNoise = collectNoiseIm(hw);
        noiseLevel = prctile_(imNoise(imNoise(:)~=0),99)*255;
        props = regionprops(bwIm,'BoundingBox','Area');
        largest = maxind([props.Area]);
        bbox = round(props(largest).BoundingBox);
        %}
        
        %find effective image "bounding box"
        bbox = [];
        bbox([1,3]) = minmax(find(bwIm(round(size(bwIm,1)/2),:)>0.9));
        lcoords = minmax(find(bwIm(:,bbox(1)+10)>0.9)');
        mcoords = minmax(find(bwIm(:,round(size(bwIm,2)/2))>0.9)');
        rcoords = minmax(find(bwIm(:,bbox(3)-10)>0.9)');
        bbox(2) = max([lcoords(1),mcoords(1),rcoords(1)]);
        bbox(4) = min([lcoords(2),mcoords(2),rcoords(2)])-bbox(2);

        
        [dfzCalTmpStart,~,~,dfzApdCalTmpStart] = Calibration.aux.collectTempData(hw,runParams,fprintff,'Before DFZ calibration:');
        for j = 1:3
            [pzrsIBiasStart(j),pzrsVBiasStart(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
        end
        captures = {calibParams.dfz.captures.capture(:).type};
        trainImages = strcmp('train',captures);
        testImages = ~trainImages;
        for i=1:length(captures)
            cap = calibParams.dfz.captures.capture(i);
            targetInfo = targetInfoGenerator(cap.target);
            cap.transformation(1,1) = cap.transformation(1,1)*calibParams.dfz.sphericalScaleFactors(1);
            cap.transformation(2,2) = cap.transformation(2,2)*calibParams.dfz.sphericalScaleFactors(2);
            im(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('DFZ - Image %d',i));
            if ~strcmp('train',cap.type)
                [dfzCalTmpEnd,~,~,dfzApdCalTmpEnd] = hw.getLddTemperature();
                for j = 1:3
                    [pzrsIBiasEnd(j),pzrsVBiasEnd(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
                end
            end
        end
        if all(trainImages)
            [dfzCalTmpEnd,~,~,dfzApdCalTmpEnd] = hw.getLddTemperature();
            for j = 1:3
                [pzrsIBiasEnd(j),pzrsVBiasEnd(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
            end
        end
        dfzTmpRegs.FRMW.dfzCalTmp = single(dfzApdCalTmpStart+dfzApdCalTmpEnd)/2;
        dfzTmpRegs.FRMW.dfzApdCalTmp = single(dfzCalTmpStart+dfzCalTmpEnd)/2;
        dfzTmpRegs.FRMW.dfzVbias = single(pzrsVBiasStart+pzrsVBiasEnd)/2;
        dfzTmpRegs.FRMW.dfzIbias = single(pzrsIBiasStart+pzrsIBiasEnd)/2;
        for i = 1:numel(captures)
            cap = calibParams.dfz.captures.capture(i);
            targetInfo = targetInfoGenerator(cap.target);
            
            
        CB = CBTools.Checkerboard (im(i).i, 'targetType', 'checkerboard_Iv2A1','imageRotatedBy180',true);
        pts = CB.getGridPointsMat;
        gridSize = CB.getGridSize;
        grid = [gridSize(1),gridSize(2),1];  
            
            targetInfo.cornersX = grid(1);
            targetInfo.cornersY = grid(2);
            d(i).i = im(i).i;
            d(i).c = im(i).c;
            d(i).z = im(i).z;
            d(i).pts = pts;
            d(i).grid = grid;
            d(i).pts3d = create3DCorners(targetInfo)';
            d(i).rpt = Calibration.aux.samplePointsRtd(im(i).z,pts,regs);
            
            
            croppedBbox = bbox;
            cropRatioX = 0.2;
            cropRatioY = 0.1;
            croppedBbox(1) = croppedBbox(1) + cropRatioX*croppedBbox(3);
            croppedBbox(3) = (1-2*cropRatioX)*croppedBbox(3);
            croppedBbox(2) = croppedBbox(2) + cropRatioY*croppedBbox(4);
            croppedBbox(4) = (1-2*cropRatioY)*croppedBbox(4);
            croppedBbox = int32(croppedBbox);
            imCropped = zeros(size(im(i).i));
            imCropped(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3)) = ...
                im(i).i(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3));
            CB = CBTools.Checkerboard (imcroped, 'targetType', 'checkerboard_Iv2A1','imageRotatedBy180',true);
            ptsCropped = CB.getGridPointsMat;
            gridCropped = [size(ptsCropped,1),size(ptsCropped,2),1];
            gridCropped(end+1) = 1;
            
            d(i).ptsCropped = ptsCropped;
            d(i).gridCropped = gridCropped;
            d(i).rptCropped = Calibration.aux.samplePointsRtd(im(i).z,ptsCropped,regs);
            
        end
        Calibration.DFZ.saveDFZInputImage(d,runParams);
        % dodluts=struct;
        %% Collect stats  dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov
        [dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,[],[],runParams);
        results.potentialPitchFixInDegrees = dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov(1)/4096;
        fprintff('Pitch factor fix in degrees = %.2g (At the left & right sides of the projection)\n',results.potentialPitchFixInDegrees);
%         [dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,[],[],runParams);
        r.reset();
        
        fw.setRegs(dfzRegs,fnCalib);
        fw.setRegs(dfzTmpRegs,fnCalib);
        regs = fw.get(); 
        hw.setReg('DIGGsphericalScale',regs.DIGG.sphericalScale);
        hw.shadowUpdate;
        
        
        if ~isempty(d(testImages))
            [~,results.extraImagesGeomErr] = Calibration.aux.calibDFZ(d(testImages),regs,calibParams,fprintff,0,1,[],runParams);
            fprintff('geom error on test set =%.2g\n',results.extraImagesGeomErr);
        end
        
        

        if(results.geomErr<calibParams.errRange.geomErr(2))
            fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
%             fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoValidCalib.txt');
%             [regs,luts]=fw.get();%run autogen
%             fw.genMWDcmd('DEST|DIGG|EXTLdsm',fnAlgoTmpMWD);
%             hw.runScript(fnAlgoTmpMWD);
%             hw.shadowUpdate();
            calibPassed = 1;
        else
            fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
        end
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,false);
        end
        
        
    else
        fprintff('[?] skipped\n');
    end
end
function imNoise = collectNoiseIm(hw)
        hw.cmd('iwb e2 06 01 00'); % Remove bias
        hw.cmd('iwb e2 08 01 0'); % modulation amp is 0
        hw.cmd('iwb e2 03 01 10');% internal modulation (from register)
        pause(0.1);
        imNoise = hw.getFrame(10).i;
        hw.cmd('iwb e2 03 01 90');% 
        hw.cmd('iwb e2 06 01 70'); % Return bias
end
function [results] = calibrateROI(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Calibrating ROI... \n');
    if (runParams.ROI)
%         d = hw.getFrame(10);
%         roiRegs = Calibration.roi.runROICalib(d,calibParams);
        regs = fw.get(); % run bootcalcs
        %% Get spherical of both directions:
        r = Calibration.RegState(hw);
        r.add('DIGGsphericalEn'    ,true     );
        r.set();
        fprintff('[-] Collecting up/down frames... ');
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'ROI - Make sure image is bright',1);
        [imUbias,imDbias]=Calibration.dataDelay.getScanDirImgs(hw,1);
        pause(0.1);
        fprintff('Done.\n');
        % Remove modulation as well to get a noise image
        
        imNoise = collectNoiseIm(hw);

        % Ambient value - Mean of the center 21x21 (arbitrary) patch in the noise image.
        results.ambVal = mean(vec(imNoise(size(imNoise,1)/2-10:size(imNoise,1)/2+10, size(imNoise,2)/2-10:size(imNoise,2)/2+10)));
        r.reset();
        
        
        [roiRegs] = Calibration.roi.calibROI(imUbias,imDbias,imNoise,regs,calibParams,runParams);
        fw.setRegs(roiRegs, fnCalib);
        fw.get(); % run bootcalcs
%         fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoROICalib.txt');
%         fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
%         hw.runScript(fnAlgoTmpMWD);
%         hw.shadowUpdate();
        fprintff('[v] Done(%ds)\n',round(toc(t)));
        
        fovData = Calibration.validation.calculateFOV(imUbias,imDbias,imNoise,regs);
        results.upDownFovDiff = sum(abs(fovData.laser.minMaxAngYup-fovData.laser.minMaxAngYdown));
        fprintff('Mirror opening angles slow and fast:      [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngX);
        fprintff('                                          [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngY);
        fprintff('Laser opening angles slow (up):           [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXup);
        fprintff('Laser opening angles slow (down):         [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXdown);
        fprintff('Laser opening angles fast (up):           [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYup);
        fprintff('Laser opening angles fast (down):         [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYdown);
        fprintff('Laser up/down fov diff:  %2.3g degrees.\n',results.upDownFovDiff);
    else
        fprintff('[?] skipped\n');
    end
end
function [results,luts] = fixAng2XYBugWithUndist(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Fixing ang2xy using undist table...\n');
    if(runParams.undist)
        [udistlUT.FRMW.undistModel,udistRegs,results.maxPixelDisplacement,results.undistRms] = Calibration.Undist.calibUndistAng2xyBugFix(fw);
        udistRegs.DIGG.undistBypass = false;
        fw.setRegs(udistRegs,fnCalib);
        fw.setLut(udistlUT);
        [~,luts]=fw.get();
        if(results.maxPixelDisplacement<calibParams.errRange.maxPixelDisplacement(2))
            fprintff('[v] undist calib passed[e=%g] [undistRms=%2.2f]\n',results.maxPixelDisplacement,results.undistRms);
        else
            fprintff('[x] undist calib failed[e=%g] [undistRms=%2.2f]\n',results.maxPixelDisplacement,results.undistRms);
            
        end
        ttt=[tempname '.txt'];
        fw.genMWDcmd('DIGGundist_|DIGG|DEST|CBUF',ttt);
        hw.runPresetScript('maReset');
        pause(0.1);
        hw.runScript(ttt);
        pause(0.1);
        hw.runPresetScript('maRestart');
        pause(0.1);
        hw.shadowUpdate();

    else
        [~,luts]=fw.get();
        fprintff('[?] skipped\n');
    end
end
function writeVersionAndIntrinsics(hw,verValue,verValueFull,fw,fnCalib,calibParams,fprintff)
    regs = fw.get();
    intregs.DIGG.spare=zeros(1,8,'uint32');
    intregs.DIGG.spare(1)=verValueFull;
    intregs.DIGG.spare(2)=typecast(single(regs.FRMW.xfov(1)),'uint32');
    intregs.DIGG.spare(3)=typecast(single(regs.FRMW.yfov(1)),'uint32');
    intregs.DIGG.spare(4)=typecast(single(regs.FRMW.laserangleH),'uint32');
    intregs.DIGG.spare(5)=typecast(single(regs.FRMW.laserangleV),'uint32');
    intregs.DIGG.spare(6)=verValue; %config version
    intregs.DIGG.spare(7) = uint32(typecast(int16(regs.FRMW.calMarginL),'uint16'))*2^16 + uint32(typecast(int16(regs.FRMW.calMarginR),'uint16'));
    intregs.DIGG.spare(8) = uint32(typecast(int16(regs.FRMW.calMarginT),'uint16'))*2^16 + uint32(typecast(int16(regs.FRMW.calMarginB),'uint16'));
    intregs.JFIL.spare=zeros(1,8,'uint32');
    %[zoCol,zoRow] = Calibration.aux.zoLoc(fw);
    intregs.JFIL.spare(1)=uint32(regs.FRMW.zoWorldRow(1))*2^16 + uint32(regs.FRMW.zoWorldCol(1));
    intregs.JFIL.spare(2)=typecast(regs.FRMW.dfzCalTmp,'uint32');
    intregs.JFIL.spare(3)=typecast(single(regs.FRMW.pitchFixFactor),'uint32');
    intregs.JFIL.spare(4)=typecast(single(regs.FRMW.polyVars(1)),'uint32');
    intregs.JFIL.spare(5)=typecast(single(regs.FRMW.polyVars(2)),'uint32');
    intregs.JFIL.spare(6)=typecast(single(regs.FRMW.polyVars(3)),'uint32');
    intregs.JFIL.spare(7)=typecast(regs.FRMW.dfzApdCalTmp,'uint32');
    
    
    dcorSpares = typecast(hw.read('DCORspare')','single');
    dcorSpares(3:5) = single(regs.FRMW.dfzVbias);
    dcorSpares(6:8) = single(regs.FRMW.dfzIbias);
    intregs.DCOR.spare = dcorSpares;
    
    
    
    fw.setRegs(intregs,fnCalib);
%     fw.get();
    
    fprintff('Zero Order Pixel Location: [%d,%d]\n',uint32(regs.FRMW.zoWorldRow(1)),uint32(regs.FRMW.zoWorldCol(1)));
end

function writeCalibRegsProps(fw,fnCalib)
    regs = fw.get();
    intregs.FRMW.calImgHsize=regs.GNRL.imgHsize;
    intregs.FRMW.calImgVsize=regs.GNRL.imgVsize;

    fw.setRegs(intregs,fnCalib);
    fw.get();
    
end

function burn2Device(hw,calibPassed,runParams,calibParams,fprintff,t)
    
    
    doCalibBurn = false;
    fprintff('[!] setting burn calibration...');
    if(runParams.burnCalibrationToDevice)
        if(calibPassed)
            doCalibBurn=true;
            fprintff('Done(%ds)\n',round(toc(t)));
        else
            fprintff('skiped, failed calibration.\n');
        end
    else
        fprintff('skiped\n');
    end
    
    doConfigBurn = false;
    fprintff('[!] setting burn configuration...');
    if(runParams.burnConfigurationToDevice)
        doConfigBurn=true;
        fprintff('Done(%ds)\n',round(toc(t)));
    else
        fprintff('skiped\n');
    end
    
     if doCalibBurn
        fprintff('[!] burning...');
        calibOutput=fullfile(runParams.outputFolder,'calibOutputFiles');
        hw.burnCalibConfigFiles(calibOutput); 
        fprintff('Done(%ds)\n',round(toc(t)));
     end
    
end
function res = noCalibrations(runParams)
    res = ~(runParams.DSM || runParams.gamma || runParams.dataDelay || runParams.ROI || runParams.DFZ || runParams.undist ||runParams.rgb || runParams.minRangePreset || runParams.maxRangePreset || runParams.init );
end
function res = onlyRGBCalib(runParams)
    res = ~(runParams.DSM || runParams.gamma || runParams.dataDelay || runParams.ROI || runParams.DFZ || runParams.undist) && runParams.rgb;
end
function RegStateSetOutDir(Outdir)
    global g_reg_state_dir;
    g_reg_state_dir = Outdir;
end
function runParams = updateRunParamsForCalibrationAfterThermalCalib(runParams)
    runParams.DSM = 0;
    runParams.minRangePreset = 0;
    runParams.maxRangePreset = 0;
end