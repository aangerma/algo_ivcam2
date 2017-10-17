function [vStruct] = verifyDCOR(cor2verifier,adoConnection,mySessionID,vStruct)
    
    blockName = 'DCOR';
    corrOffset = cor2verifier.corrOffset;
    corr = cor2verifier.corr;
    cImg = cor2verifier.cImg;
    
    corrRatio = (squeeze(max(corr,[],1))./squeeze(min(corr,[],1)));
    % Submit metrics
    metricName1 = 'CorrOffset';
    metricValue1 = nanmean(corrOffset(:));
    metricVer1 = 1;
    blockVer1 = 1;
    fullstat = 1;
    [~,vStruct.(blockName).(metricName1)] = SQL.addNewResult(adoConnection,mySessionID,blockName,metricName1,metricValue1,metricVer1,blockVer1,corrOffset,fullstat);
    
    metricName2 = 'Confidence';
    metricValue2 = nanmean(cImg(:));
    metricVer2 = 1;
    blockVer2 = 1;
    fullstat = 1;
    [~,vStruct.(blockName).(metricName2)] = SQL.addNewResult(adoConnection,mySessionID,blockName,metricName2,metricValue2,metricVer2,blockVer2,cImg,fullstat);
    
   metricName3 = 'CorrRatio';
    metricValue3 = nanmean(corrRatio(:));
    metricVer3 = 1;
    blockVer3 = 1;
    fullstat = 1;
    [~,vStruct.(blockName).(metricName3)] = SQL.addNewResult(adoConnection,mySessionID,blockName,metricName3,metricValue3,metricVer3,blockVer3,corrRatio,fullstat);
end