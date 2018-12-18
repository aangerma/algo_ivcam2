function pass = mergeScores(results,errRange,fprintff,Calib0Valid1)
    if ~exist('Calib0Valid1','var')
        Calib0Valid1 = 0;
    end
    strstatus = {'failed','passed'};
    f = fieldnames(results);
    inRange=zeros(length(f),1);
    errRangeFields = fieldnames(errRange);
    for i = 1:length(f)
        currMetricName = Calibration.aux.findCurrectErrorPattern(errRangeFields,f{i});
        inRange(i) = results.(f{i}) >= errRange.(currMetricName)(1) && results.(f{i}) <= errRange.(currMetricName)(2);
        strrange = sprintf('[%2.1f..%2.1f]',errRange.(currMetricName));
        ll=fprintff('% -20s: %6s %5.2g %15s\n',f{i},strstatus{inRange(i)+1},results.(f{i}),strrange);
    end
    pass = min(inRange);
    fprintff('%s\n',repmat('-',1,ll));
    if Calib0Valid1
        fprintff('% -20s: %s\n','Validation status',strstatus{pass+1});
    else
        fprintff('% -20s: %s\n','Calibration status',strstatus{pass+1});
    end
    
end

