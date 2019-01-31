function [  ] = collectTempData( hw,runParams,stageStr )
%COLLECTTEMPDATA reads the Ldd temperature and add it to log

logName = fullfile(runParams.outputFolder,'temperatures.log');
temp = hw.getLddTemperature();
fid = fopen(logName,'a');
line = sprintf('%-30s %5.2f\r\n',stageStr,temp);
fprintf(fid, line);
fclose(fid);


end

