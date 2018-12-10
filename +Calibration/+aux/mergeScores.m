function pass = mergeScores(results,errRange,fprintff,Calib0Valid1)
    if ~exist('Calib0Valid1','var')
        Calib0Valid1 = 0;
    end
    f = fieldnames(results);
    inRange=zeros(length(f),1);
    for i = 1:length(f)
        inRange(i) = results.(f{i}) >= errRange.(f{i})(1) && results.(f{i}) <= errRange.(f{i})(2);
    end
    pass = min(inRange);
    
    
    for i = 1:length(f)
        if inRange(i) strstatus = 'passed'; else  strstatus = 'failed'; end
        strrange = sprintf('[%2.1f..%2.1f]',errRange.(f{i}));
        ll=fprintff('% -20s: %6s %5.2g %15s\n',f{i},strstatus,results.(f{i}),strrange);
    end
    if pass strstatus = 'passed'; else  strstatus = 'failed'; end
    fprintff('%s\n',repmat('-',1,ll));
    if Calib0Valid1
        fprintff('% -20s: %s\n','Validation status',strstatus);
    else
        fprintff('% -20s: %s\n','Calibration status',strstatus);
    end

end