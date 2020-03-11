function [resTable,resStruct] = aggregateSparkMetricsData(baseDirs,revType,fileToSearch)
    %aggregateSparkMetricsData find all units under one or more baseDirs,
    % and read the metric in the spark file under all revision of type
    % revType (IV for IQ val, ACC for ACC, etc.) into one struct or table
    
    %inputs handling
    if ischar (baseDirs) || isstring(baseDirs)
        baseDirs = {baseDirs};
    end
    if ~exist('revType','var')
        revType = 'IV';
    end
    if ~exist('fileToSearch','var')
        fileToSearch = 'log.txt';
    end
    %main loop - go over all base dirs
    resStruct = [];
    for i=1:length(baseDirs)
        baseDir = baseDirs{i};
        [~,lbl] = fileparts(baseDir);
        %find all units
        units = listModulesInFolderIV2(baseDir);
        
        %go over all units
        for uid = 1:length(units)
            
            %find and go over all revisions
            revs = du.analysis.findAllRevisions(fullfile(baseDir,units{uid}),fileToSearch,revType);
            for rid=1:length(revs)
                %find the spark file
                sparkFile = dirFiles(fullfile(baseDir,units{uid},revs{end}),'SPARK*.xml',1);
                if isempty(sparkFile)
                    continue;
                end
                %add "meta data"
                mData = struct('Label',lbl,'UnitID',units{uid},'Revision',revs{end});
                
                %read the spark file and extarct the metrics data
                sparkData = readHvmSparkMetrics(sparkFile{end});
                
                %attached the metadata
                sparkData = mergestruct(mData,sparkData);
                
                %add to the main struct
                resStruct = mergeResStructs(resStruct,sparkData);
                
            end
        end
    end
    
    %convert to table
    resTable = struct2table(resStruct);
end

function allRes = mergeResStructs(allRes,newRes)
    %helper function to handle the migration of 2 possible different
    %structs
    if isempty(allRes)
        idx = 1;
        allRes = struct();
    else
        idx = length(allRes) + 1;
    end
    fields = fieldnames(newRes);
    for fid=1:length(fields)
        allRes(idx).(fields{fid}) = newRes.(fields{fid});
    end
end