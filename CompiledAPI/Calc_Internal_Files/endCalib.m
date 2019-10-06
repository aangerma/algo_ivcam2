function [results ,undistLuts] = End_Calib_Calc_int(runParams,delayRegs, dsmregs,roiRegs,dfzRegs,thermalRegs,results,fnCalib, fprintff, calibParams)
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
