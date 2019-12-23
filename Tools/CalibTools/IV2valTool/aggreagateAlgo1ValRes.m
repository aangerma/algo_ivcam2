function resTable = aggreagateAlgo1ValRes(baseDirs)
    
    valReportFname = 'Validation\ValReport.xml';
    resTable = {'Label','Unit ID','Revision','Test','Metric','Score'};
    idx = 2;
    if isstring(baseDirs) || ischar(baseDirs)
        baseDirs = {baseDirs};
    end
    
    for i=1:length(baseDirs)
        baseDir = baseDirs{i};
        [~,label] = fileparts(baseDir);
        units = listModulesInFolderIV2(baseDir);
        for uid = 1:length(units)
            unitDir = fullfile(baseDir,units{uid});
            revs = du.analysis.findAllRevisions(unitDir,valReportFname,'PC');
            for rid=1:length(revs)
                res = xml2struct(fullfile(unitDir, revs{rid} ,valReportFname));
                flds = fieldnames(res);
                for tid = 1:length(flds)
                    testStruct = res.(flds{tid});
                    metrics = fieldnames(testStruct);
                    for mid = 1:length(metrics)
                        score = testStruct.(metrics{mid});
                        if isnumeric(score) && isscalar(score)
                            resTable(idx,:) = {label,units{uid},revs{rid},flds{tid},metrics{mid},score};
                            idx = idx+1;
                        end
                    end
                end
            end
            
        end
    end
    
end