function [lddTmptr,mcTmptr,maTmptr,tSense,vSense ] = collectTempData( hw,runParams,fprintff,stageStr )
%COLLECTTEMPDATA reads the Ldd temperature and add it to log




logName = fullfile(runParams.outputFolder,'temperatures.log');
[lddTmptr,mcTmptr,maTmptr,tSense,vSense ] = hw.getLddTemperature();
for i = 1:3
    [iBias(i),vBias(i)] = hw.pzrPowerGet(i,5);
end
fid = fopen(logName,'a');
c = clock;
line = sprintf('%s %-30s\nlddTmptr:%5.2f,mcTmptr:%5.2f,maTmptr:%5.2f,tSense:%5.2f,vSense:%5.2f,vBias:(%5.3f,%5.3f,%5.3f),iBias:(%f,%f,%f)\r\n',sprintf('%02.0f:%02.0f:%02.0f',c(4:end)),stageStr,lddTmptr,mcTmptr,maTmptr,tSense,vSense,vBias,iBias);
fprintf(fid, line);
fclose(fid);

fprintff(line);


end

