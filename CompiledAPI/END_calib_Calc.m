%function [results ,luts] = END_calib_Calc(verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams,undist_flag)
function [results ,luts] = END_calib_Calc(delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams,undist_flag,version,configurationFolder, eepromRegs, eepromBin, afterThermalCalib_flag)
% the function calcualte the undistored table based on the result from the DFZ and ROI then prepare calibration scripts  
% to burn into the eprom. later on the function will create calibration
% eprom table. the FW will process them and set the registers as needed. 
%
% inputs:
%   verValue     - just major version
%   verValueFull - full version
%   delayRegs    - output of the of IR/Z delay (the actual setting value as in setabsDelay fundtion)
%   dsmregs      - output of the DSM_Calib_Calc
%   roiRegs      - output of the ROI_Calib_Calc
%   dfzRegs      - output of the DFZ_Calib_Calc
%   results      - incrmental result of prev algo.
%   fnCalib      - base directory of calib/config files (calib.csv ,
%   config.csv , mode.csv)
%   calibParams  - calibration params.
%                                  
% output:
%   results - incrmntal result 
%   luts - undistort table.
    if ~exist('afterThermalCalib_flag','var')
        afterThermalCalib_flag = 0;
    end
    global g_output_dir g_calib_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn; % g_regs g_luts;
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

    
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'delayRegs', 'dsmregs' ,'roiRegs','dfzRegs','results','fnCalib' ,'calibParams');
    end
    runParams.outputFolder = g_output_dir;
    runParams.undist = undist_flag;
    runParams.afterThermalCalib = afterThermalCalib_flag;
    runParams.version=version;
    runParams.configurationFolder=configurationFolder; 
    [~,~,versionBytes] = calibToolVersion();
    verValue           = uint32(versionBytes(1))*2^8 + uint32(versionBytes(2));%0x00000203
    verValueFull       = uint32(versionBytes(1))*2^16 +uint32(versionBytes(2))*2^8+uint32(versionBytes(3));%0x00020300 

    fw = Firmware(g_calib_dir);
    if(isempty(eepromRegs) || ~isstruct(eepromRegs)) % called from HVM tester
        EPROMstructure  = load(fullfile(g_calib_dir,'eepromStructure.mat'));
        EPROMstructure  = EPROMstructure.updatedEpromTable;
        eepromBin       = uint8(eepromBin);
        eepromRegs      = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
    end
    [dfzRegs, thermalRegs] = getThermalRegs(dfzRegs, eepromRegs, runParams.afterThermalCalib);
    
    [results ,luts] = final_calib(runParams,verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,thermalRegs,results,fnCalib, fprintff, calibParams,g_output_dir);    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files', [func_name '_out.mat']);
        save(fn,'results', 'luts');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

function [results ,undistLuts] = final_calib(runParams,verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,thermalRegs,results,fnCalib, fprintff, calibParams,output_dir)
    t = tic;
    %% load inital FW.
%    fw = Pipe.loadFirmware(internalFolder);
    path = fileparts(fnCalib);
    if(exist(fullfile(path , 'regsDefinitions.frmw'), 'file') == 2)
        fw = Pipe.loadFirmware(path,'tablesFolder',path); % incase of DLL assume table same folder as fnCalib
    else
        fw = Pipe.loadFirmware(path); % use default path of table folder
    end
    %% set regs from all algo calib
    vregs.FRMW.calibVersion = uint32(hex2dec(single2hex(runParams.version)));
    vregs.FRMW.configVersion = uint32(hex2dec(single2hex(runParams.version)));
    fw.setRegs(vregs,fnCalib);
    fw.setRegs(thermalRegs,fnCalib);
    fw.setRegs(dsmregs,  fnCalib); % DO NOT CHANGE THE ORDER OF THE CALLS TO setRegs
    fw.setRegs(delayRegs,fnCalib); 
    fw.setRegs(dfzRegs,  fnCalib);  
    fw.setRegs(roiRegs,  fnCalib);
    
    %% prepare spare register to store the fov. 
%     writeVersionAndIntrinsics(verValue,verValueFull,fw,fnCalib,calibParams,fprintff);
    
    [results,undistRegs,undistLuts] = fixAng2XYBugWithUndist(runParams, calibParams, results,fw,fnCalib, fprintff, t);
    fw.setRegs(undistRegs,fnCalib);
    fw.setLut(undistLuts);
    regs = fw.get();
    intregs.FRMW.calImgHsize = regs.GNRL.imgHsize;
    intregs.FRMW.calImgVsize = regs.GNRL.imgVsize;
    rtdOverYRegs = calcRtdOverYRegs(regs,runParams); % Translating RTD Over Y fix to txPWRpd regs
    fw.setRegs(intregs,fnCalib);
    fw.setRegs(rtdOverYRegs,fnCalib);
    
    
    temp_dir = fullfile(output_dir,'AlgoInternal');
    mkdirSafe(temp_dir);
    fn = fullfile(temp_dir,'postUndistState.txt');
    fw.genMWDcmd('DIGG|DEST|CBUF',fn);
    %% prepare preset table
    presetPath = path; 
    Calibration.presets.updatePresetsEndOfCalibration(runParams,calibParams,presetPath,results);
    
    %% Print image final fov
    [results,~] = Calibration.aux.calcImFov(fw,results,calibParams,fprintff);
    fnUndsitLut = fullfile(output_dir,'FRMWundistModel.bin32');
    fw.writeUpdated(fnCalib);
    io.writeBin(fnUndsitLut,undistLuts.FRMW.undistModel);
%     % write old firmware files to sub folder
%     oldFirmwareOutput=fullfile(output_dir,'oldCalibfiles'); 
%     mkdirSafe(oldFirmwareOutput);
%     fw.writeFirmwareFiles(oldFirmwareOutput);
%     % write new firmware files to another sub folder
    calibOutput=fullfile(output_dir,'calibOutputFiles');
    mkdirSafe(calibOutput);
    fw.generateTablesForFw(calibOutput,0,runParams.afterThermalCalib); 
%     calibTempTableFn = fullfile(calibOutput,sprintf('Dynamic_Range_Info_CalibInfo_Ver_05_%02d.bin',mod(runParams.version*100,100)));    
%      fw.writeDynamicRangeTable(calibTempTableFn,presetPath);
    
    results = addRegs2result(results,dsmregs,delayRegs,dfzRegs,roiRegs);
end
function results = addRegs2result(results,dsmregs,delayRegs,dfzRegs,roiRegs)
    results.EXTLconLocDelaySlow = (delayRegs.EXTL.conLocDelaySlow);
    results.EXTLconLocDelayFastC = (delayRegs.EXTL.conLocDelayFastC);
    results.EXTLconLocDelayFastF = (delayRegs.EXTL.conLocDelayFastF);
    results.DESTtxFRQpd = (dfzRegs.DEST.txFRQpd(1));
end

function [results,udistRegs,udistlUT] = fixAng2XYBugWithUndist(runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Fixing ang2xy using undist table...\n');
    if(runParams.undist)
        [udistlUT.FRMW.undistModel,udistRegs,results.maxPixelDisplacement] = Calibration.Undist.calibUndistAng2xyBugFix(fw,runParams);
        udistRegs.DIGG.undistBypass = false;
        if(results.maxPixelDisplacement<calibParams.errRange.maxPixelDisplacement(2))
            fprintff('[v] undist calib passed[e=%g]\n',results.maxPixelDisplacement);
        else
            fprintff('[x] undist calib failed[e=%g]\n',results.maxPixelDisplacement);
            
        end
%        ttt=[tempname '.txt'];
%        hw.runScript(ttt);
%        hw.shadowUpdate();
        fprintff('[v] Done(%ds)\n',round(toc(t)));
    else
        [~,luts]=fw.get();
        fprintff('[?] skipped\n');
    end
end

function rtdOverYRegs = calcRtdOverYRegs(regs,runParams)
targetRows = linspace(1,single(regs.GNRL.imgVsize),numel(regs.DEST.txPWRpd));
tanY = (targetRows-1)*regs.DEST.p2aya + regs.DEST.p2ayb;
rtd2Add = regs.FRMW.rtdOverY(1)*tanY.^2 + regs.FRMW.rtdOverY(2)*tanY.^4 + regs.FRMW.rtdOverY(3)*tanY.^6;
rtdOverYRegs.DEST.txPWRpd = single(-rtd2Add/1024);
ff = Calibration.aux.invisibleFigure;
plot(linspace(1,single(regs.GNRL.imgVsize),65),rtd2Add);
title('RTD to add over Y');
xlabel('y_im')
ylabel('mm')
Calibration.aux.saveFigureAsImage(ff,runParams,'DFZ','RTD_Fix_Over_Y');
end


function [dfzRegs, thermalRegs] = getThermalRegs(dfzRegs, eepromRegs, afterThermalCalib)
thermalRegs = struct;
if afterThermalCalib
    dfzRegs.FRMW.dfzCalTmp          = eepromRegs.FRMW.dfzCalTmp;
    dfzRegs.FRMW.dfzApdCalTmp       = eepromRegs.FRMW.dfzApdCalTmp;
    dfzRegs.FRMW.dfzVbias           = eepromRegs.FRMW.dfzVbias;
    dfzRegs.FRMW.dfzIbias           = eepromRegs.FRMW.dfzIbias;
    thermalRegs.FRMW.atlMinVbias1   = eepromRegs.FRMW.atlMinVbias1;
    thermalRegs.FRMW.atlMaxVbias1   = eepromRegs.FRMW.atlMaxVbias1;
    thermalRegs.FRMW.atlMinVbias2   = eepromRegs.FRMW.atlMinVbias2;
    thermalRegs.FRMW.atlMaxVbias2   = eepromRegs.FRMW.atlMaxVbias2;
    thermalRegs.FRMW.atlMinVbias3   = eepromRegs.FRMW.atlMinVbias3;
    thermalRegs.FRMW.atlMaxVbias3   = eepromRegs.FRMW.atlMaxVbias3;
else % dfzRegs was already enriched in DFZ_calib, thermalRegs are irrelevant
    thermalRegs.FRMW.atlMinVbias1   = single(1);
    thermalRegs.FRMW.atlMaxVbias1   = single(3);
    thermalRegs.FRMW.atlMinVbias2   = single(1);
    thermalRegs.FRMW.atlMaxVbias2   = single(3);
    thermalRegs.FRMW.atlMinVbias3   = single(1);
    thermalRegs.FRMW.atlMaxVbias3   = single(3);
end
end