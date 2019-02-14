function [lddTmptr,mcTmptr,maTmptr,tSense,vSense ] = collectTempData( hw,runParams,fprintff,stageStr )
%COLLECTTEMPDATA reads the Ldd temperature and add it to log




logName = fullfile(runParams.outputFolder,'temperatures.log');
[lddTmptr,mcTmptr,maTmptr,tSense,vSense ] = hw.getLddTemperature();
fid = fopen(logName,'a');
c = clock;
line = sprintf('%s %-30s\nlddTmptr:%5.2f,mcTmptr:%5.2f,maTmptr:%5.2f,tSense:%5.2f,vSense:%5.2f\r\n',sprintf('%02.0f:%02.0f:%02.0f',c(4:end)),stageStr,lddTmptr,mcTmptr,maTmptr,tSense,vSense);
fprintf(fid, line);
fclose(fid);

fprintff(line);


end

