function [results] = validationIterativeEnvelope(hw, unitData, calibParams, runParams, fprintff)

%tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
timeBetweenFrames = calibParams.warmUp.timeBetweenFrames;
%maxTime2WaitSec = maxTime2Wait*60;

pN = 1000;
tempsForPlot = nan(1,pN);
timesForPlot = nan(1,pN);
plotDataI = 1;

% isXGA = all(runParams.calibRes==[768,1024]);
% if isXGA
%     hw.cmd('ENABLE_XGA_UPSCALE 1');
% end
runParams.rgb = calibParams.gnrl.rgb.doStream;
runParams.rgbRes = calibParams.gnrl.rgb.res;
Calibration.aux.startHwStream(hw,runParams);
Calibration.thermal.thermalValidationInit(hw,runParams);

prevTmp = hw.getLddTemperature();
prevTime = 0;
tempsForPlot(plotDataI) = prevTmp;
timesForPlot(plotDataI) = prevTime/60;
plotDataI = mod(plotDataI,pN)+1;

startTime = tic;
%% Collect data until temperature doesn't raise any more
finishedHeating = false; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next

fprintff('[-] Starting heating stage (waiting for diff<%1.1f over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',prevTmp);

i = 0;
tempFig = figure(190789);
plot(timesForPlot,tempsForPlot); grid on, xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));

%framesData = zeros(1,1000000); % 
sz = hw.streamSize();
% ATCpath_temp = fullfile(ivcam2tempdir,'ATC');
% if(exist(ATCpath_temp,'dir'))
%     rmdir(ATCpath_temp,'s');
% end
while ~finishedHeating
    % collect data without performing any calibration
    i = i + 1;
    [frameBytes, framesData(i)] = prepareFrameData(hw,startTime,calibParams);  
    [finishedHeating,~, ~] = ThermalValidationDataFrame_Calc(finishedHeating, unitData, framesData(i),sz, frameBytes, calibParams);
    

    
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
hw.stopStream;
fprintff('Stopped Stream...\n');
if finishedHeating % always true at this point
    [~,~, resultsThermal] = ThermalValidationDataFrame_Calc(finishedHeating, unitData, framesData(end),sz, frameBytes, calibParams);
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
    plot(heatTimeVec,[tempVec.tsense])
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

function [frameBytes, frameData] = prepareFrameData(hw,startTime,calibParams)
    %    frame = hw.getFrame();
    %    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , nof_frames , path(i));

    [frameData.temp.ldd,frameData.temp.mc,frameData.temp.ma,frameData.temp.apd] = hw.getLddTemperature;
    frameData.temp.shtw2 = hw.getHumidityTemperature;
    for j = 1:3
        [frameData.iBias(j), frameData.vBias(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
    end
    if calibParams.gnrl.rgb.doStream
        frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZICrgb', calibParams.gnrl.Nof2avg);
    else
        frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZIC', calibParams.gnrl.Nof2avg);
    end
    frameData.time = toc(startTime);
%     frameData.flyback = hw.cmd('APD_FLYBACK_VALUES_GET');
%     frameData.maVoltage = hw.getMaVoltagee();
    % RX tracking
end
