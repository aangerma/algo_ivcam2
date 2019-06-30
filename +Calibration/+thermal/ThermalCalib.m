function [result] = ThermalCalib(hw,regs,calibParams,runParams,fprintff,maxTime2Wait,app)

%tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
timeBetweenFrames = calibParams.warmUp.timeBetweenFrames;
%maxTime2WaitSec = maxTime2Wait*60;

pN = 1000;
tempsForPlot = nan(1,pN);
timesForPlot = nan(1,pN);
plotDataI = 1;

Calibration.aux.startHwStream(hw,runParams);
if calibParams.gnrl.sphericalMode
    hw.setReg('DIGGsphericalEn',1);
    hw.cmd(sprintf('mwd a0020c00 a0020c04 %x // DIGGsphericalScale',typecast(regs.DIGG.sphericalScale,'uint32')))
%     hw.setReg('DIGGsphericalScale',dec2hex(typecast(regs.DIGG.sphericalScale,'uint32')));
    hw.setReg('DESTdepthAsRange',1);
    hw.setReg('DESTbaseline$',single(0));
    hw.setReg('DESTbaseline2',single(0));
    hw.shadowUpdate;
end


prevTmp = hw.getLddTemperature();
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
    [result, tableResults]  = TemDataFrame_Calc(regs, framesData(i),sz, path,calibParams,maxTime2Wait);
%    rmdir(path,'s');
    finishedHeating = (result~=0);
    
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
    [frameData.iBias(1), frameData.vBias(1)] = hw.pzrPowerGet(1,5);
    [frameData.iBias(2), frameData.vBias(2)] = hw.pzrPowerGet(2,5);
    [frameData.iBias(3), frameData.vBias(3)] = hw.pzrPowerGet(3,5);
    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , 1 , path); %after mareg with main remove local calls.
    frameData.time = toc(startTime);
%    frameData.ptsWithZ = cornersData(frame,regs,calibParams);
end

