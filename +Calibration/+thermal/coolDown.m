function [ info ] = coolDown(hw,calibParams,runParams,fprintff)

startTime = tic;
finishedCooling = 0;
coolTimeVec(1) = toc(startTime);
[coolTmpVec(1,1),coolTmpVec(1,2),coolTmpVec(1,3),coolTmpVec(1,4),coolTmpVec(1,5)] = hw.getLddTemperature;
tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;

fprintff('[-] Starting cooling stage (waiting for diff<%1.1f degrees over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',coolTmpVec(1,1));

while ~finishedCooling
    pause(tempSamplePeriod);
    coolTimeVec(end+1) = toc(startTime);
    newI = size(coolTmpVec,1)+1;
    [coolTmpVec(newI,1),coolTmpVec(newI,2),coolTmpVec(newI,3),coolTmpVec(newI,4),coolTmpVec(newI,5)] = hw.getLddTemperature;
    
    fprintff(', %2.2f',coolTmpVec(newI,1));
    if coolTmpVec(newI-1,1) - coolTmpVec(newI,1) < tempTh
        finishedCooling = 1;
    end
end
fprintff('\n');
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(coolTimeVec,coolTmpVec(:,1))
    title('Cooling Stage'); grid on;xlabel('sec');ylabel('ldd temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Cooling',sprintf('LddTempOverTime'));
end
info.duration = coolTimeVec(end);
info.startTemp = coolTmpVec(1,1);
info.endTemp = coolTmpVec(end,1);


end

