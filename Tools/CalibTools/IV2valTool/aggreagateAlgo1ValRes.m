function resTable = aggreagateAlgo1ValRes(baseDirs)
    %aggreagateAlgo1ValRes finds all the valreport.xml in all the base dir
    %and put everything in a single excel file for comparison. for more
    %than one base dir, pass a cell array with all the base directories.
    %the returned resTable can eb written using xlswrite function
    valReportFname = 'Validation\ValReport.xml';
    resTable = {'Label','Unit ID','Revision','Test','Metric','Score'};
    idx = 2;
    if isstring(baseDirs) || ischar(baseDirs)
        baseDirs = {baseDirs};
    end
    %for all base folders
    for i=1:length(baseDirs)
        baseDir = baseDirs{i};
        [~,label] = fileparts(baseDir);
        units = listModulesInFolderIV2(baseDir);
        
        %for all units
        for uid = 1:length(units)
            unitDir = fullfile(baseDir,units{uid});
            revs = du.analysis.findAllRevisions(unitDir,valReportFname,'AV'); %PC is the prefix for the revision
            
            %for all reveisions, read the report
            for rid=1:length(revs)
                res = xml2struct(fullfile(unitDir, revs{rid} ,valReportFname));
                flds = fieldnames(res);
                
                %add all test in the report to the result file
                for tid = 1:length(flds)
                    testStruct = res.(flds{tid});
                    metrics = fieldnames(testStruct);
                    
                    %take all metric results that are numeric - ignore
                    %error, name, etc.
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