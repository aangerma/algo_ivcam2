function  [calibPassed] = runAlgoThermalCalibration(runParamsFn,calibParamsFn, fprintff,spark,app)
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
    initConfiguration(hw,fw,runParams,fprintff,t);

    
    hw.cmd('DIRTYBITBYPASS');
    hw.cmd('algo_thermloop_en 0');
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    
    fprintff('Opening stream...');
%     Calibration.aux.startHwStream(hw,runParams);
    hw.startStream(0,calibParams.gnrl.calibRes);
    fprintff('Done(%ds)\n',round(toc(t)));
    %% Verify unit's configuration version
   [verValue,verValuefull] = getVersion(hw,runParams);  
    
    %% Set coarse DSM values 
    calibrateCoarseDSM(hw, runParams, calibParams, fprintff,t);
    
    %% Get a frame to see that hwinterface works.
    fprintff('Capturing frame...');
    hw.getFrame();
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% ::calibrate delays::
    [results, calibPassed ,delayRegs] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff);
    if ~calibPassed
        return;
    end
    % start cooling procedure
    hw.stopStream;
    
    %% load EPROM structure suitible for calib version tool 
    [regs,eepromRegs,eepromBin] = Calibration.thermal.readDFZRegsForThermalCalculation(hw,1,calibParams);
    fprintff('Done(%ds)\n',round(toc(t)));
    
    regs.EXTL.conLocDelaySlow   = delayRegs.EXTL.conLocDelaySlow;
    regs.EXTL.conLocDelayFastC  = delayRegs.EXTL.conLocDelayFastC;
    regs.EXTL.conLocDelayFastF  = delayRegs.EXTL.conLocDelayFastF;
    %regs.EXTL.conLocOutVDelay   = delayRegs.EXTL.conLocOutVDelay;
    
    if typecast(hw.read('DESTtmptrOffset'),'single') ~= 0
        error('Algo thermal loop was active. Please disconnect and reconnect the unit before running.');
    end
    % thermal calibration 
    maxCoolTime = inf;
    maxHeatTime = calibParams.warmUp.maxWarmUpTime;
    coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,maxCoolTime); % cool down
    [calibPassed, results] = Calibration.thermal.AlgoThermalCalib(hw, regs, eepromRegs, eepromBin, calibParams, runParams, fw, fnCalib, results, fprintff, maxHeatTime, app);
    
    results = UpdateResultsStruct(results);
    Calibration.aux.logResults(results,runParams);
    Calibration.aux.writeResults2Spark(results,spark,calibParams.errRange,write2spark,'Cal');
    
    fprintff('[!] Calibration ended - ');
    if(calibPassed==0)
        fprintff('FAILED.\n');
    else %% burn tables
        fprintff('PASSED.\n');
        fprintff('Burning algo thermal table...');
        version = typecast(eepromRegs.FRMW.calibVersion,'single');
        whole = floor(version);
        frac = mod(version*100,100);

        calibpostfix = sprintf('_Ver_%02d_%02d',whole,frac);

        calibParams.fwTable.name = [calibParams.fwTable.name,calibpostfix,'.bin'];
        tableName = fullfile(runParams.outputFolder,calibParams.fwTable.name);

        try
            cmdstr = sprintf('WrCalibInfo %s',tableName);
            hw.cmd(cmdstr);
            fprintff('Done\n');
        catch
            fprintf('Failed to write Algo_Thermal_Table to EPROM. You are probably using an unsupported fw version.\n');
            calibPassed = 0;
        end
        fprintff('Burning algo calibration table...');
        try
            algoCalibInfoName = fullfile(runParams.outputFolder,['Algo_Calibration_Info_CalibInfo',calibpostfix,'.bin']);
            cmdstr = sprintf('WrCalibInfo %s',algoCalibInfoName);
            hw.cmd(cmdstr);
            fprintff('Done\n');
        catch
            fprintf('Failed to write Algo_Calibration_Info to EPROM. You are probably using an unsupported fw version.\n');
            calibPassed = 0;
        end
    end
    clear hw;
end
function [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn)
    runParams=xml2structWrapper(runParamsFn);
    calibParams = xml2structWrapper(calibParamsFn);
    
end
function [runParams,fnCalib,fnUndsitLut] = defineFileNamesAndCreateResultsDir(runParams,calibParams)
    runParams.internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');
    mkdirSafe(runParams.outputFolder);
    mkdirSafe(runParams.internalFolder);
    fnCalib     = fullfile(runParams.internalFolder,'calib.csv');
    fnUndsitLut = fullfile(runParams.internalFolder,'FRMWundistModel.bin32');
    initFldr = fullfile(fileparts(mfilename('fullpath')),runParams.configurationFolder);
    initPresetsFolder = fullfile(fileparts(mfilename('fullpath')),'+presets','+defaultValues');
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

function initConfiguration(hw,fw,runParams,fprintff,t)  
    fprintff('init hw configuration...');
    if(runParams.init)
%         fnAlgoInitMWD  =  fullfile(runParams.internalFolder,filesep,'algoInit.txt');
%         fw.genMWDcmd('^(?!MTLB|EPTG|FRMW|EXTLvAPD|EXTLauxShadow.*$).*',fnAlgoInitMWD);
%         hw.runPresetScript('maReset');
%         pause(0.1);
%         hw.runScript(fnAlgoInitMWD);
%         pause(0.1);
%         hw.runPresetScript('maRestart');
%         pause(0.1);
%         hw.shadowUpdate();
%         hw.setUsefullRegs();
%         fprintff('Done(%ds)\n',round(toc(t)));
        % Create config calib files
        fprintff('[-] Burning default config calib files...');
%         fw.writeFirmwareFiles(fullfile(runParams.internalFolder,'configFiles'));
%         fw.writeDynamicRangeTable(fullfile(runParams.internalFolder,'configFiles',sprintf('Dynamic_Range_Info_CalibInfo_Ver_00_00.bin')));
        vregs.FRMW.calibVersion = uint32(hex2dec(single2hex(calibToolVersion)));
        vregs.FRMW.configVersion = uint32(hex2dec(single2hex(calibToolVersion)));
        fw.setRegs(vregs,'');
        fw.generateTablesForFw(fullfile(runParams.internalFolder,'initialCalibFiles'));
        fw.writeDynamicRangeTable(fullfile(runParams.internalFolder,'initialCalibFiles',sprintf('Dynamic_Range_Info_CalibInfo_Ver_04_%02.0f.bin',mod(calibToolVersion,1)*100)));
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
        [delayRegs,delayCalibResults]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,fprintff,runParams,calibParams);
        
        fw.setRegs(delayRegs,fnCalib);
        
        results.conLocDelaySlow = delayRegs.EXTL.conLocDelaySlow;
        results.conLocDelayFastC = delayRegs.EXTL.conLocDelayFastC;
        results.conLocDelayFastF = delayRegs.EXTL.conLocDelayFastF;

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
        delayRegs = struct;
        fprintff('skipped\n');
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
function res = noCalibrations(runParams)
    res = ~(runParams.DSM || runParams.dataDelay);
end
function results = UpdateResultsStruct(results)
    results.thermalRtdRefTemp = results.rtd.refTemp;
    results.thermalRtdSlope = results.rtd.slope;
    results.thermalAngyMaxScale = max(abs(results.angy.scale));
    results.thermalAngyMaxOffset = max(abs(results.angy.offset));
    results.thermalAngyMinVal = results.angy.minval;
    results.thermalAngyMaxVal = results.angy.maxval;
    results.thermalAngxMaxScale = max(abs(results.angx.scale));
    results.thermalAngxMaxOffset = max(abs(results.angx.offset));
    results.thermalAngxP0 = results.angx.p0;
    results.thermalAngxP1 = results.angx.p1;
    results = rmfield(results, {'rtd', 'angy', 'angx', 'table'});
end