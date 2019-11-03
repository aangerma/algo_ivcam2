function [calibPassed, results] = AlgoThermalCalib(hw, regs, eepromRegs, eepromBin, calibParams, runParams, fw, fnCalib, results, fprintff, maxTime2Wait, app)

%tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
timeBetweenFrames = calibParams.warmUp.timeBetweenFrames;
%maxTime2WaitSec = maxTime2Wait*60;

pN = 1000;
tempsForPlot = nan(1,pN);
timesForPlot = nan(1,pN);
plotDataI = 1;

isXGA = all(runParams.calibRes==[768,1024]);
if isXGA
    hw.cmd('ENABLE_XGA_UPSCALE 1');
end
Calibration.aux.startHwStream(hw,runParams);
if calibParams.gnrl.sphericalMode
    hw.setReg('DIGGsphericalEn',1);
    hw.cmd(sprintf('mwd a0020c00 a0020c04 %x // DIGGsphericalScale',typecast(regs.DIGG.sphericalScale,'uint32')))
%     hw.setReg('DIGGsphericalScale',dec2hex(typecast(regs.DIGG.sphericalScale,'uint32')));
    hw.setReg('DESTdepthAsRange',1);
    hw.setReg('DESTbaseline$',single(0));
    hw.setReg('DESTbaseline2',single(0));
    hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
    hw.cmd('mwd a00e1890 a00e1894 00000001 // JFILinvBypass');
    hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');    
    hw.shadowUpdate;
end


prevTmp = hw.getLddTemperature();
prevTime = 0;
tempsForPlot(plotDataI) = prevTmp;
timesForPlot(plotDataI) = prevTime/60;
plotDataI = mod(plotDataI,pN)+1;

startTime = tic;
%% Collect data until temperature doesn't raise any more
finishedHeating = false; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next
manualCaptures = isfield(runParams,'manualCaptures') && runParams.manualCaptures;
if manualCaptures
    app.stopWarmUpButton.Visible = 'on';
    app.stopWarmUpButton.Enable = 'on'; 
end

fprintff('[-] Starting heating stage (waiting for diff<%1.1f over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',prevTmp);

i = 0;
tempFig = figure(190789);
plot(timesForPlot,tempsForPlot); grid on, xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));

%framesData = zeros(1,1000000); % 
sz = hw.streamSize();
ATCpath_temp = fullfile(ivcam2tempdir,'ATC');
if(exist(ATCpath_temp,'dir'))
    rmdir(ATCpath_temp,'s');
end
while ~finishedHeating
    % collect data without performing any calibration
    i = i + 1;
    path = fullfile(ATCpath_temp,sprintf('thermal%d',i));
    framesData(i) = prepareFrameData(hw,startTime,calibParams,path);  %
    [finishedHeating,~, ~,~,~] = TmptrDataFrame_Calc(finishedHeating, regs, eepromRegs, eepromBin, framesData(i),sz, path,calibParams,maxTime2Wait);
    
    if tempFig.isvalid
        tempsForPlot(plotDataI) = framesData(i).temp.ldd;
        timesForPlot(plotDataI) = framesData(i).time/60;
        figure(190789);plot(timesForPlot([plotDataI+1:pN,1:plotDataI]),tempsForPlot([plotDataI+1:pN,1:plotDataI])); grid on, xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));drawnow;
        plotDataI = mod(plotDataI,pN)+1;
    end
    pause(timeBetweenFrames);
    if i == 4
        sceneFig = figure(190790);
        imshow(rot90(hw.getFrame().i,2));
        title('Scene Image');
    end
end
if finishedHeating % always true at this point
    t = tic;
    % operate delays calibration at stable (reference) state
    [results, calibPassed ,delayRegs] = Calibration.dataDelay.calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff, false);
    if ~calibPassed
        return;
    end
    regs.EXTL.conLocDelaySlow       = delayRegs.EXTL.conLocDelaySlow;
    regs.EXTL.conLocDelayFastC      = delayRegs.EXTL.conLocDelayFastC;
    regs.EXTL.conLocDelayFastF      = delayRegs.EXTL.conLocDelayFastF;
    regs.FRMW.conLocDelayFastSlope  = delayRegs.FRMW.conLocDelayFastSlope;
    regs.FRMW.conLocDelaySlowSlope  = delayRegs.FRMW.conLocDelaySlowSlope;
    regs.FRMW.dfzCalTmp             = delayRegs.FRMW.dfzCalTmp; % overriden later by a similar value
    % operate fine DSM calibration at stable (reference) state
    dsmRegs = calibrateDSM(hw, fw, runParams, calibParams,fnCalib, fprintff,t);
    regs.EXTL.dsmXscale     = dsmRegs.EXTL.dsmXscale;
    regs.EXTL.dsmXoffset    = dsmRegs.EXTL.dsmXoffset;
    regs.EXTL.dsmYscale     = dsmRegs.EXTL.dsmYscale;
    regs.EXTL.dsmYoffset    = dsmRegs.EXTL.dsmYoffset;
    results.dsmXscale       = regs.EXTL.dsmXscale;
    results.dsmXshift       = regs.EXTL.dsmXoffset;
    results.dsmYscale       = regs.EXTL.dsmYscale;
    results.dsmYshift       = regs.EXTL.dsmYoffset;
    % noting reference state for thermal calibration (referred to as "DFZ state" for backward compatibility)
    regs.FRMW.dfzCalTmp     = framesData(i).temp.ldd; % overriding Tref from end of delays calibration (delta should be small)
    regs.FRMW.dfzApdCalTmp  = framesData(i).temp.apdTmptr;
    regs.FRMW.dfzVbias      = framesData(i).vBias;
    regs.FRMW.dfzIbias      = framesData(i).iBias;
    fprintff('Algo Calib reference Ldd Temp: %2.2fdeg\n',regs.FRMW.dfzCalTmp);
    fprintff('Algo Calib reference vBias: (%2.2f,%2.2f,%2.2f)\n',regs.FRMW.dfzVbias);
    fprintff('Algo Calib reference iBias: (%2.2f,%2.2f,%2.2f)\n',regs.FRMW.dfzIbias);
    % perform algo thermal calibration
    i = i + 1;
    path = fullfile(ATCpath_temp,sprintf('thermal%d',i));
    framesData(i) = prepareFrameData(hw,startTime,calibParams,path);
    [~,calibPassed, resultsThermal,~,~] = TmptrDataFrame_Calc(finishedHeating, regs,eepromRegs, eepromBin, framesData(i),sz, path,calibParams,maxTime2Wait); 
    fnames = fieldnames(resultsThermal);
    for iField = 1:length(fnames)
        results.(fnames{iField}) = resultsThermal.(fnames{iField});
    end
end


if i >=4 && sceneFig.isvalid
    close(sceneFig);
end
if tempFig.isvalid
    close(tempFig);
end

hw.stopStream;
fprintff('Done\n');

% if manualSkip
%     reason = 'Manual skip';
% elseif reachedRequiredTempDiff
%     reason = 'Stable temperature';
% elseif reachedTimeLimit
%     reason = 'Passed time limit';
% elseif reachedCloseToTKill
%     reason = 'Reached close to TKILL';
% elseif raisedFarAboveCalibTemp
%     reason = 'Raised far above calib temperature';
% end
% fprintff('Finished heating reason: %s\n',reason);


heatTimeVec = [framesData.time];
tempVec = [framesData.temp];
LddTempVec = [tempVec.ldd];

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,LddTempVec)
    title('Heating Stage'); grid on;xlabel('sec');ylabel('ldd temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('LddTempOverTime'),1);
    
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,[tempVec.ma])
    title('Heating Stage'); grid on;xlabel('sec');ylabel('ma temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MaTempOverTime'),1);
    
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,[tempVec.mc])
    title('Heating Stage'); grid on;xlabel('sec');ylabel('mc temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('McTempOverTime'),1);
    
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,[tempVec.apdTmptr])
    title('Heating Stage'); grid on;xlabel('sec');ylabel('Apd temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('ApdTempOverTime'),1);
    
end
info.duration = heatTimeVec(end);
info.startTemp = LddTempVec(1);
info.endTemp = LddTempVec(end);


if manualCaptures
    app.stopWarmUpButton.Visible = 'off';
    app.stopWarmUpButton.Enable = 'off'; 
    Calibration.aux.globalSkip(1,0);
end
end

function frameData = prepareFrameData(hw,startTime,calibParams,path)
%    frame = hw.getFrame();
%    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , nof_frames , path(i));

    [frameData.temp.ldd,frameData.temp.mc,frameData.temp.ma,frameData.temp.apdTmptr] = hw.getLddTemperature;
%    frameData.pzrShifts = hw.pzrShifts;
    for j = 1:3
        [frameData.iBias(j), frameData.vBias(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
    end
    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , calibParams.gnrl.Nof2avg , path); %after mareg with main remove local calls.
    frameData.time = toc(startTime);
end

function dsmRegs = calibrateDSM(hw,fw, runParams, calibParams, fnCalib, fprintff, t)

    fprintff('[-] DSM calibration...\n');
    if(runParams.DSM)
        dsmRegs = Calibration.DSM.DSM_Calib(hw,fprintff,calibParams,runParams);
        fw.setRegs(dsmRegs,fnCalib);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        dsmRegs = struct;
        fprintff('[?] skipped\n');
    end
    
end