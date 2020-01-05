function [ info ] = coolDown(hw,calibParams,runParams,fprintff,maxTime2Wait)
if ~runParams.coolDown
   info = [];
   return; 
end
startTime = tic;
finishedCooling = 0;
coolTimeVec(1) = toc(startTime);
[coolTmpVec(1,1),coolTmpVec(1,2),coolTmpVec(1,3),coolTmpVec(1,4)] = hw.getLddTemperature;
tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
maxTime2WaitSec = maxTime2Wait*60;

fprintff('[-] Starting cooling stage (waiting for diff<%1.1f degrees over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',coolTmpVec(1,1));

while ~finishedCooling
    pause(tempSamplePeriod);
    coolTimeVec(end+1) = toc(startTime);
    newI = size(coolTmpVec,1)+1;
    [coolTmpVec(newI,1),coolTmpVec(newI,2),coolTmpVec(newI,3),coolTmpVec(newI,4)] = hw.getLddTemperature;
    
    fprintff(', %2.2f',coolTmpVec(newI,1));
    if coolTmpVec(newI-1,1) - coolTmpVec(newI,1) < tempTh || (coolTimeVec(end) > maxTime2WaitSec)
        finishedCooling = 1;
    end
end
fprintff('\n');
if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    plot(coolTimeVec,coolTmpVec(:,1))
    title('Cooling Stage'); grid on;xlabel('sec');ylabel('ldd temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Cooling',sprintf('LddTempOverTime'),1);
end
info.duration = coolTimeVec(end);
info.startTemp = coolTmpVec(1,1);
info.endTemp = coolTmpVec(end,1);


end

