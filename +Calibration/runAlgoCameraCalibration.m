function  [calibPassed] = runAlgoCameraCalibration(runParamsFn,calibParamsFn, fprintff,spark,app)
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
    runParams.afterAlgo2 = true;
    
    if noCalibrations(runParams)
        calibPassed = -1;
        return;
    end
    %% output all RegState to files 
    RegStateSetOutDir(runParams.outputFolder);

    %% Calibration file names
    [runParams,fnCalib,fnUndsitLut] = defineFileNamesAndCreateResultsDir(runParams,calibParams);
    
    fprintff('Starting calibration:\n');
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f.%1.0f\n','version',runParams.version,runParams.subVersion);
    
    %% Load init fw
    fprintff('Loading initial firmware...');
    fw = Pipe.loadFirmware(runParams.internalFolder);
    fw.get();%run autogen
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Load hw interface
    hw = loadHWInterface(runParams,fw,fprintff,t);
    [~,serialNum,~] = hw.getInfo(); 
    fprintff('%-15s %8s\n','serial',serialNum);
    
    %% call HVM_cal_init
    calib_dir = fileparts(fnCalib);
    [calibParams , ~] = HVM_Cal_init(calibParamsFn,calib_dir,fprintff,runParams.outputFolder);

    
    %% Start stream to load the configuration
    Calibration.aux.collectTempData(hw,runParams,fprintff,'Before starting stream:');
    
    %% Init hw configuration
    atlregs = initConfiguration(hw,fw,runParams,fprintff,t);

    
    hw.cmd('DIRTYBITBYPASS');
    hw.cmd('algo_thermloop_en 1');
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    
    fprintff('Opening stream...');
%     Calibration.aux.startHwStream(hw,runParams);
    hw.startStream(0,runParams.calibRes);
    fprintff('Done(%ds)\n',round(toc(t)));
    %% Verify unit's configuration version
   [verValue,verValuefull] = getVersion(hw,runParams);  
    
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
    
    %% Verify Scan Direction
    [results,calibPassed] = validateScanDirection(hw, results,runParams,calibParams, fprintff);
    if ~calibPassed
      return 
    end
    
    
   %% Validate spherical fill rate
   [results,calibPassed] = validateCoverage(hw,1, runParams, calibParams,results, fprintff);
   if ~calibPassed
       return 
   end
   Calibration.aux.collectTempData(hw,runParams,fprintff,'Before los validation:');
   [results,calibPassed] = validateLos(hw, runParams, calibParams,results, fprintff);
   if ~calibPassed
       return
   end
    %% ::gamma:: 
	results = calibrateDiggGamma(runParams, calibParams, results, fprintff, t);
	calibrateJfilGamma(fw, calibParams,runParams,fnCalib,fprintff);

    %% Calibrate min range preset
    [results] = calibratePresets(hw, results,runParams,calibParams, fprintff,fw);
    
    %% ::DFZ::  Apply DFZ result if passed (It affects next calibration stages)
    
%    [results,calibPassed] = calibrateDFZ(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    [results,calibPassed,dfzRegs] = Calibration.DFZ.DFZ_calib(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t);
    if ~calibPassed
       return 
    end

    %% ::ROI::
    [results ,roiRegs] = Calibration.roi.ROI_calib(hw, dfzRegs, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    
    %% Undist and table burn
%    results = END_calib_Calc(verValue, verValuefull ,delayRegs, dsmregs , roiRegs,dfzRegs,results,fnCalib,calibParams,runParams.undist);
    delayRegs.EXTL.conLocDelaySlow = hw.read('EXTLconLocDelaySlow');
    delayRegs.EXTL.conLocDelayFastC = hw.read('EXTLconLocDelayFastC');
    delayRegs.EXTL.conLocDelayFastF = hw.read('EXTLconLocDelayFastF');
    dsmregs.EXTL.dsmXscale  = typecast(hw.read('EXTLdsmXscale'), 'single');
    dsmregs.EXTL.dsmXoffset = typecast(hw.read('EXTLdsmXoffset'), 'single');
    dsmregs.EXTL.dsmYscale  = typecast(hw.read('EXTLdsmYscale'), 'single');
    dsmregs.EXTL.dsmYoffset = typecast(hw.read('EXTLdsmYoffset'), 'single');
    %TODO: verify that END_calib_Calc has everything it needs
    results = END_calib_Calc(delayRegs, dsmregs , roiRegs,dfzRegs,atlregs,results,fnCalib,calibParams,runParams.undist,runParams.afterAlgo2,runParams.version,runParams.configurationFolder);
    
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
        
        %% Coverage within ROI 
        [results,calibPassed] = validateCoverage(hw,0, runParams, calibParams,results, fprintff);
        if ~calibPassed
           return 
        end
        %% Validate DFZ before reset
        [results,calibPassed] = preResetDFZValidation(hw,fw,results,calibParams,runParams,fprintff);
        
        
    catch e
        fprintff('[!] ERROR:%s\n',strtrim(e.message));
        fprintff('CoverageValidation or preResetDFZValidation failed. Skipping...\n');
    end

    %% merge all scores outputs
    calibPassed = Calibration.aux.mergeScores(results,calibParams.errRange,fprintff,0);
    
    %% Burn 2 device
    hw.stopStream;
    burn2Device(hw,1,runParams,calibParams,@fprintf,t);


 
    %% Collecting hardware state
    if runParams.saveRegState
        fprintff('Collecting registers state...');
        hw.getRegsFromUnit(fullfile(runParams.outputFolder,'calibrationRegState.txt') ,0 );
        fprintff('Done\n');
    end
    %% Long range calibration- calib res
    if runParams.maxRangePreset
        Calstate =findLongRangeStateCal(calibParams,runParams.calibRes);
        if(isnan(Calstate))
            error('calibration resolution doesnt fit to any of long range states');
        end
        hw.cmd('rst');
        pause(10);
        clear hw;
        pause(1);
        hw = HWinterface;
        hw.cmd('DIRTYBITBYPASS');
        fprintff('Calibrating long range preset, starting stream.\n');
        hw.startStream(0,runParams.calibRes);
        results = calibrateLongRangePreset(hw,runParams.calibRes,Calstate,results,runParams,calibParams, fprintff);
    end
    %% Long range calibration- calib res 2 if needed
    if runParams.maxRangePreset
        if(strcmp(Calstate,'state1'))
            stateTotest='state2';
        else
            stateTotest='state1';
        end
        secondRes=calibParams.presets.long.(stateTotest).resolution;
        if(~isempty(secondRes))
            hw.stopStream;
            hw.cmd('rst');
            pause(10);
            clear hw;
            pause(1);
            hw = HWinterface;
            hw.cmd('DIRTYBITBYPASS');
            fprintff('Test second state for long range preset, starting stream.\n');
            hw.startStream(0,secondRes);
            results = calibrateLongRangePreset(hw,secondRes,stateTotest,results,runParams,calibParams, fprintff);
            
        end
    end
    presetPath = fullfile(runParams.outputFolder,'AlgoInternal');
    calibTempTableFn = fullfile(runParams.outputFolder,'calibOutputFiles',sprintf('Dynamic_Range_Info_CalibInfo_Ver_05_%02d.bin',mod(runParams.version*100,100)));
    fw.writeDynamicRangeTable(calibTempTableFn,presetPath);
    
    fprintff('[-] Burning preset table...');
    try
        hw = HWinterface;
        hw.cmd(['WrCalibInfo ',calibTempTableFn]);
        fprintff('Done\n');
    catch
        fprintff('failed to burn preset table\n');
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
        initConfiguration(hw,fw,runParams,fprintff,t);
    else
        fprintff('PASSED.\n');
    end
    fprintff('Calibration finished(%d)\n',round(toc(t)));
    
    %% Validation
    
%     Calibration.validation.validateCalibration(runParams,calibParams,fprintff);
    %% rgb calibration
    if calibPassed
        calibPassed = calRGB(hw,calibParams,runParams,results,calibPassed,fprintff,fnCalib,t);
    end
    clear hw;
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
            fnRgbTable = fullfile(runParams.outputFolder,...
                sprintf('RGB_Calibration_Info_CalibInfo_Ver_%02d_%02d.bin',rgbTable.version));
            writeAllBytes(rgbTable.data,fnRgbTable);
            try
                hw.cmd(sprintf('WrCalibInfo "%s"',fnRgbTable));
            catch
                fprintff('Failed to write RGB calibration table. Check if EEPROM TOC supports RGB.\n');
            end
        end
        rgbResults.rgbIntReprojRms = results.rgbIntReprojRms;
        rgbResults.rgbExtReprojRms = results.rgbExtReprojRms;
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
        
        
        
        [dfzRes,~ ] = Calibration.validation.validateDFZ( hw,frames,@sprintf,calibParams,runParams);
        if calibParams.dfz.sampleRTDFromWhiteCheckers
            results.eGeomSphericalDis = dfzRes.GeometricErrorWht;
        else
            results.eGeomSphericalDis = dfzRes.GeometricErrorReg;
        end
        targetInfo = targetInfoGenerator('Iv2A1');
        targetInfo.cornersX = 20;
        targetInfo.cornersY = 28;
        [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(framesSpherical.i, 1);
%         [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(framesSpherical.i, 1,0,0.2, 1);
        grid = [size(pts,1),size(pts,2),1];
        framesSpherical.pts = pts;
        framesSpherical.grid = grid;
        framesSpherical.pts3d = create3DCorners(targetInfo)';
        framesSpherical.rpt = Calibration.aux.samplePointsRtd(framesSpherical.z,pts,regs);
%         framesSpherical.rpt = Calibration.aux.samplePointsRtdAdvanced(framesSpherical.z,pts,regs,colors,0,1);
        if exist(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat'), 'file') == 2
            load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); % loads undistTpsModel
        else
            tpsUndistModel = [];
        end
        calibParams.dfz.calibrateOnCropped = 0;
        [~,dfzResults] = Calibration.aux.calibDFZ(framesSpherical,regs,calibParams,fprintff,0,1,[],runParams,tpsUndistModel);
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

function atlregs = initConfiguration(hw,fw,runParams,fprintff,t)  
    fprintff('init hw configuration...');
    if(runParams.init)
        eRegs = hw.readAlgoEEPROMtable();
        if ~runParams.dataDelay
            vregs.EXTL.conLocDelaySlow = eRegs.EXTL.conLocDelaySlow;
            vregs.EXTL.conLocDelayFastC = eRegs.EXTL.conLocDelayFastC;
            vregs.EXTL.conLocDelayFastF = eRegs.EXTL.conLocDelayFastF;
        end
        fprintff('[-] Burning default config calib files...');
%         fw.writeFirmwareFiles(fullfile(runParams.internalFolder,'configFiles'));
%         fw.writeDynamicRangeTable(fullfile(runParams.internalFolder,'configFiles',sprintf('Dynamic_Range_Info_CalibInfo_Ver_00_00.bin')));
        vregs.FRMW.calibVersion = uint32(hex2dec(single2hex(calibToolVersion)));
        vregs.FRMW.configVersion = uint32(hex2dec(single2hex(calibToolVersion)));
        atlregs.FRMW.atlMinVbias1 = eRegs.FRMW.atlMinVbias1;
        atlregs.FRMW.atlMaxVbias1 = eRegs.FRMW.atlMaxVbias1;
        atlregs.FRMW.atlMinVbias2 = eRegs.FRMW.atlMinVbias2;
        atlregs.FRMW.atlMaxVbias2 = eRegs.FRMW.atlMaxVbias2;
        atlregs.FRMW.atlMinVbias3 = eRegs.FRMW.atlMinVbias3;
        atlregs.FRMW.atlMaxVbias3 = eRegs.FRMW.atlMaxVbias3;
        fw.setRegs(vregs,'');
        fw.setRegs(atlregs,'');
        fw.generateTablesForFw(fullfile(runParams.internalFolder,'initialCalibFiles'),0,runParams.afterAlgo2);
	%TODO: verify that generateTablesForFw doesn't miss something because of afterAlgo2 flag
        fw.writeDynamicRangeTable(fullfile(runParams.internalFolder,'initialCalibFiles',sprintf('Dynamic_Range_Info_CalibInfo_Ver_05_%02.0f.bin',mod(calibToolVersion,1)*100)));
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

function [calibParams , ret] = HVM_Cal_init(fn_calibParams,calib_dir,fprintff,output_dir)
    % Sets all global variables
    if(~exist('output_dir','var'))
        output_dir = fullfile(ivcam2tempdir,'\cal_tester\output');
    end
    debug_log_f         = 0;
    verbose             = 0;
    save_input_flag     = 1;
    save_output_flag    = 1;
    dummy_output_flag   = 0;
    ret = 1;
    [calibParams ,~] = cal_init(output_dir,calib_dir,fn_calibParams, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag,fprintff);
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
function state =findLongRangeStateCal(calibParams,resolution)
        state1Res=calibParams.presets.long.state1.resolution;
        state2Res=calibParams.presets.long.state2.resolution; 
        switch mat2str(resolution)
            case mat2str(state1Res)
                state='state1';
            case mat2str(state2Res)
                state='state2'; 
            otherwise 
                state=nan; 
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
        calibPassed = (isLeft) && (~isTop);% Currenly the scan directoin makes it so the gray circle is below and to the left of the black circle.
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

function imNoise = collectNoiseIm(hw)
        hw.cmd('iwb e2 06 01 00'); % Remove bias
        hw.cmd('iwb e2 08 01 0'); % modulation amp is 0
        hw.cmd('iwb e2 03 01 10');% internal modulation (from register)
        pause(0.1);
        imNoise = hw.getFrame(10).i;
        hw.cmd('iwb e2 03 01 90');% 
        hw.cmd('iwb e2 06 01 70'); % Return bias
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
    
    
%     hw.burn2device(runParams.outputFolder,doCalibBurn,doConfigBurn);
     if doCalibBurn
        fprintff('[!] burning...');
        calibOutput=fullfile(runParams.outputFolder,'calibOutputFiles');
        hw.burnCalibConfigFiles(calibOutput); 
        fprintff('Done(%ds)\n',round(toc(t)));
     end
    
end
function res = noCalibrations(runParams)
    res = ~(runParams.gamma || runParams.ROI || runParams.DFZ || runParams.undist ||runParams.rgb || runParams.minRangePreset || runParams.maxRangePreset || runParams.init );
end
function res = onlyRGBCalib(runParams)
    res = ~(runParams.gamma || runParams.ROI || runParams.DFZ || runParams.undist) && runParams.rgb;
end
function RegStateSetOutDir(Outdir)
    global g_reg_state_dir;
    g_reg_state_dir = Outdir;
end
