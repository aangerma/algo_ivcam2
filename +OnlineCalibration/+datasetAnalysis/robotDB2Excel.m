function [] = robotDB2Excel()
basePath = 'X:\Data\AcData';
testFolder ={'05211217','05251739','05251431','05252120','05270914','05271104','05271633','05280735','05302107'};
counter = 1;
for k = 1:numel(testFolder)
    T = readtable(fullfile(basePath,testFolder{k},'results.csv'));
    tableColNames = T.Properties.VariableNames;
    if strcmp(tableColNames{3},'sn')
        serialTemp = T.sn{1};
    else
        tempVar = table2cell(T(1,2));
        splittedStr = strsplit(tempVar{1},',');
        serialTemp = splittedStr{3};
    end
    ix = strfind(serialTemp ,'f');
    serialTemp = serialTemp(ix:end);
    
    dataSceneFolders = dir(fullfile(basePath,testFolder{k},'hScale*'));
    for iScenes = 1:numel(dataSceneFolders)
        dataFiles = dir(fullfile(basePath,testFolder{k},dataSceneFolders(iScenes).name,'*_data.mat'));
        for idataFiles = 1:numel(dataFiles)
            frameLink{counter,1} = fullfile(fullfile(basePath,testFolder{k},dataSceneFolders(iScenes).name,dataFiles(idataFiles).name));
            cameraParamsLink{counter,1} = frameLink{counter,1};
            preset{counter,1} = 'Long';
            lutLink{counter,1} = fullfile(basePath,testFolder{k},'lutTable.csv');
            serial{counter,1} = serialTemp;
            counter = counter + 1;
        end
    end
end

T = table(frameLink,cameraParamsLink,lutLink,serial,preset);
writeTablePath = OnlineCalibration.datasetAnalysis.getDbPathByType('robot');
writetable(T,writeTablePath);
end