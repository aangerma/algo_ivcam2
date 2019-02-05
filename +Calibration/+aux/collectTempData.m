function [ lddTmptr,tSense,vSense,tmpPvt ] = collectTempData( hw,runParams,stageStr )
%COLLECTTEMPDATA reads the Ldd temperature and add it to log




logName = fullfile(runParams.outputFolder,'temperatures.log');
[lddTmptr,tSense,vSense,tmpPvt] = hw.getLddTemperature();
fid = fopen(logName,'a');
c = clock;
line = sprintf('%s %-30s, lddTmptr: %5.2f, vSense: %5.2f, tSense: %5.2f, tmpPvt: %5.2f\r\n',sprintf('%02.0f:%02.0f:%02.0f',c(4:end)),stageStr,lddTmptr,vSense,tSense,tmpPvt);
fprintf(fid, line);
fclose(fid);


end

