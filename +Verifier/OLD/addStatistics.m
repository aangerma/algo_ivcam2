function [statsOut,myStatisticID]= addStatistics(adoConnection,myResultID,matrix)
    matrix = double(matrix);
    columns = {'ResultID'};
    values = {myResultID};
    output = 'StatisticID';
    [newMETRIC_STAT] = SQL.sqlInsert('METRIC_STAT',columns,values,output);
    [instrtedPK, ~] = adodb_query(adoConnection, newMETRIC_STAT);            
    myStatisticID = uint16(instrtedPK(1).statisticid);
    
    
    prctile15 = @(x) prctile(x,15); 
    prctile85 = @(x) prctile(x,85);
    columns = {'Mean','Median','Std','Min','Max','Prctile15','Prctile85'};
    funCell = {@nanmean,@nanmedian,@nanstd,@nanmin,@nanmax,prctile15,prctile85};
    values = cellfun(@(f) f(matrix(:)),funCell,'uni',0);
    statsOut = [columns;values];
    [addStats] = SQL.sqlUpdateWhere('METRIC_STAT',columns,values,'StatisticID',myStatisticID);
    adodb_query(adoConnection, addStats); 
    
    blob = SQL.image2blob(single(matrix),[16 16]);    
    [addStats] = SQL.sqlUpdateWhere('METRIC_STAT',{'Blob'},{blob},'StatisticID',myStatisticID);
    adodb_query(adoConnection, addStats); 
end