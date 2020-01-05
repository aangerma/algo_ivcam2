function [calibPassed] = ThermalCalib(hw,regs,luts,eepromRegs,eepromBin,calibParams,runParams,fprintff,maxTime2Wait,app)

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
    hw.cmd('ENABLE_XGA_UPSCALE 1')
end
Calibration.aux.startHwStream(hw,runParams);

framesWorldStart = hw.getFrame(10,0,1);
badRoiAtStart = badRoiCalibration(framesWorldStart,fprintff);
if badRoiAtStart
    fprintff('Unit suffers from bad ROI calibration at warmup start...\n');
end
if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    subplot(121);
    imagesc(framesWorldStart(1).i);
    subplot(122);
    imagesc(framesWorldStart(1).z/4,[0,1000]);colorbar;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('startUpFrame'),1);
end

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

pause(1.5);
% First frame here (mean frame)
framesCollected = hw.getFrame(10,true,1); %First frame
ixFrame = 1;

prevTmp = hw.getLddTemperature();
lastTemp4FrameCollect = prevTmp;
prevTime = 0;
tempsForPlot(plotDataI) = prevTmp;
timesForPlot(plotDataI) = prevTime/60;
plotDataI = mod(plotDataI,pN)+1;

startTime = tic;
%% Collect data until temperature doesn't raise any more
finishedHeating = 0; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next
manualCaptures = isfield(runParams,'manualCaptures') && runParams.manualCaptures;
if manualCaptures
    app.stopWarmUpButton.Visible = 'on';
    app.stopWarmUpButton.Enable = 'on'; 
end

fprintff('[-] Starting heating stage (waiting for diff<%1.1f over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',prevTmp);

i = 0;
tempFig = figure(190789);
plot(timesForPlot,tempsForPlot); xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));

%framesData = zeros(1,1000000); % 
sz = hw.streamSize();
algo2path_temp = fullfile(ivcam2tempdir,'algo2');
if(exist(algo2path_temp,'dir'))
    rmdir(algo2path_temp,'s');
end

while ~finishedHeating
    i = i + 1;
    path = fullfile(algo2path_temp,sprintf('thermal%d',i));
    framesData(i) = prepareFrameData(hw,startTime,calibParams,path);  %
%    [result,fd ,table]  = TemDataFrame_Calc(regs, framesData(i),sz, path,calibParams,maxTime2Wait);
    [finishedHeating,calibPassed, tableResults,~,~]  = TemDataFrame_Calc(regs,luts,eepromRegs,eepromBin,framesData(i),sz, path,calibParams,maxTime2Wait);
%    rmdir(path,'s');
%    finishedHeating = (result~=0);
    
    if tempFig.isvalid
        tempsForPlot(plotDataI) = framesData(i).temp.ldd;
        timesForPlot(plotDataI) = framesData(i).time/60;
        figure(190789);plot(timesForPlot([plotDataI+1:pN,1:plotDataI]),tempsForPlot([plotDataI+1:pN,1:plotDataI])); xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));drawnow;
        plotDataI = mod(plotDataI,pN)+1;
    end
    pause(timeBetweenFrames);
    
    if i == 4
        sceneFig = figure(190790);
        imshow(rot90(hw.getFrame().i,2));
        title('Scene Image');
    end
    if (framesData(i).temp.ldd - lastTemp4FrameCollect(ixFrame)) > calibParams.warmUp.deltaTemp4Fovframe
        ixFrame = ixFrame + 1;
        lastTemp4FrameCollect(ixFrame) = framesData(i).temp.ldd;
        framesCollected(ixFrame) = hw.getFrame(10,true,1);
    end
end

hw.setReg('DIGGsphericalEn',0);
hw.setReg('DESTdepthAsRange',0);
hw.shadowUpdate;
pause(1.5);
framesWorld = hw.getFrame(10,true,1);

for i = 1:length(framesCollected)
    framesCollected(i).i(:,1) = 0;
    framesCollected(i).i(:,end) = 0;
    framesCollected(i).i(1,:) = 0;
    framesCollected(i).i(end,:) = 0;
end
params.camera = struct('zMaxSubMM',hw.z2mm,'K',hw.getIntrinsics);
params.worldGridFrame = framesWorld;
params.target.name = 'Iv2A1';
params.verbose = 0;
params.nonRectangleFlag = 1;
dataDir = fullfile(runParams.outputFolder,'mat_files');
save([dataDir '\framesNparams4FovCalc.mat'],'framesCollected','params');
[score, res, dbg] = Validation.metrics.losLaserFOVAnglesDrift(framesCollected, params);
save([dataDir '\fovCalcOut.mat'], 'score', 'res', 'dbg');
minFovX = min(dbg.fovX);
maxFovX = max(dbg.fovX);
minFovY = min(dbg.fovY);
maxFovY = max(dbg.fovY);
dFovHor = maxFovX-minFovX;
dFovVer = maxFovY-minFovY;

percentFovHor = dFovHor/minFovX*100;
percentFovVer = dFovVer/minFovY*100;

if percentFovHor < calibParams.errRange.fovPercTmpChangeRangeH(1) || percentFovHor > calibParams.errRange.fovPercTmpChangeRangeH(2)
    calibPassed = false;
    fprintff('[-] Failed - Percent FOV change from start to end horizontal = %3.1f%%. Fov range=[%2g,%2g]. Th=[%2g,%2g]...\n',percentFovHor,minFovX,maxFovX,calibParams.errRange.fovPercTmpChangeRangeH);
else
    fprintff('[-] Passed - Percent FOV change from start to end horizontal = %3.1f%%  Fov range=[%2g,%2g]. Th=[%2g,%2g]...\n',percentFovHor,minFovX,maxFovX,calibParams.errRange.fovPercTmpChangeRangeH);
end
if percentFovVer < calibParams.errRange.fovPercTmpChangeRangeV(1) || percentFovVer > calibParams.errRange.fovPercTmpChangeRangeV(2)
    calibPassed = false;
    fprintff('[-] Failed - Percent FOV change from start to end vertical = %3.1f%%. Fov range=[%2g,%2g]. Th=[%2g,%2g]...\n',percentFovVer,minFovY,maxFovY,calibParams.errRange.fovPercTmpChangeRangeV);
else
    fprintff('[-] Passed - Percent FOV change from start to end vertical = %3.1f%%. Fov range=[%2g,%2g]. Th=[%2g,%2g]...\n',percentFovVer,minFovY,maxFovY,calibParams.errRange.fovPercTmpChangeRangeV);
end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    subplot(121);
    plot(lastTemp4FrameCollect,dbg.fovX); grid minor;
    xlabel('LDD temperature'); ylabel('FOV x');
    subplot(122);
    plot(lastTemp4FrameCollect,dbg.fovY); grid minor;
    xlabel('LDD temperature'); ylabel('FOV y');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating','FovChangeOverTemp',1);
end



if i >=4 && sceneFig.isvalid
    close(sceneFig);
end
if tempFig.isvalid
    close(tempFig);
end

badRoiAtEnd = badRoiCalibration(framesWorld,fprintff);
if badRoiAtEnd
    fprintff('Unit suffers from bad ROI calibration at warmup end...\n');
end
if badRoiAtEnd || badRoiAtStart
    calibPassed = 0;
else
    fprintff('No visible roi issues at start and end of warmup...\n');
end
if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    subplot(121);
    imagesc(framesWorld(1).i);
    subplot(122);
    imagesc(framesWorld(1).z/4,[0,1000]);colorbar;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('warmupEndFrame'),1);
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

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
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
    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , 1 , path); %after mareg with main remove local calls.
    frameData.time = toc(startTime);
%    frameData.ptsWithZ = cornersData(frame,regs,calibParams);
end
function res = badRoiCalibration(frames,fprintff)
fRates = arrayfun(@(s) mean(s.i(:)>0)*100,frames);
irFillRate = mean(fRates);
res = irFillRate < 100;
end
