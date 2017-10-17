function [vStruct] = verifyDRAS(pipeOutData,adoConnection,mySessionID,vStruct)
    
    blockName = 'DRAS';
    
    % Calculate metrics
    unsmoothed =  pipeOutData.cma;
    smoothed =  pipeOutData.cmaSmooth;
  
    % Submit metrics
    metricName1 = 'SmoothNans';
    metricValue1 = nanmean(smoothed(:));
    metricVer1 = 1;
    blockVer1 = 1;
    fullstat = 1;
    nnzRawSmoothed = squeeze((sum((smoothed~=0),1)))/size(smoothed,1);
    [~,vStruct.(blockName).(metricName1)] = SQL.addNewResult(adoConnection,mySessionID,blockName,metricName1,metricValue1,metricVer1,blockVer1,nnzRawSmoothed,fullstat);
     
    metricName2 = 'UnsmoothNans';
    metricValue2 = nanmean(unsmoothed(:));
    metricVer2 = 1;
    blockVer2 = 1;
    nnzRawUnsmoothed = squeeze((sum((unsmoothed~=0),1)))/size(unsmoothed,1);
    [~,vStruct.(blockName).(metricName2)] = SQL.addNewResult(adoConnection,mySessionID,blockName,metricName2,metricValue2,metricVer2,blockVer2,nnzRawUnsmoothed,fullstat);
    
end

