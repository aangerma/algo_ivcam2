function [] = dataCollectionDB2Excel(dbType)
switch dbType
    case 'aged'
        basePath = 'X:\IVCAM2_calibration _testing\AutoCalibration3_Scene&CB_aged';
        writeTablePath = OnlineCalibration.datasetAnalysis.getDbPathByType('dataCollectionAged');
    case 'normal'
        basePath = 'X:\IVCAM2_calibration _testing\AutoCalibration2_Scene&CB';
        writeTablePath = OnlineCalibration.datasetAnalysis.getDbPathByType('dataCollection');
    otherwise
        error(['No such dbType as: ' dbType]);
end

dataSceneFolders = dir(fullfile(basePath,'Scene*'));
counter = 0;
for k = 1:numel(dataSceneFolders)
    unitSnFolders = dir(fullfile(basePath,dataSceneFolders(k).name,'F*'));
    for iUnit = 1:numel(unitSnFolders)
        presetFolders = dir(fullfile(basePath,dataSceneFolders(k).name,unitSnFolders(iUnit).name,'*_Preset'));
        for iPreset = 1:numel(presetFolders)
            depthResFolder = dir(fullfile(basePath,dataSceneFolders(k).name,unitSnFolders(iUnit).name,presetFolders(iPreset).name,'*x*'));
            for iRes = 1:numel(depthResFolder)
                counter = counter + 1;
                frameLink{counter,1} = fullfile(basePath,dataSceneFolders(k).name,unitSnFolders(iUnit).name,presetFolders(iPreset).name,depthResFolder(iRes).name,'Scene');
                lutLink{counter,1} = fullfile(basePath,dataSceneFolders(k).name,unitSnFolders(iUnit).name,presetFolders(iPreset).name,depthResFolder(iRes).name,'lutTable.csv');
                cameraParamsLink{counter,1} = frameLink{counter,1};
                serial{counter,1} = unitSnFolders(iUnit).name;
                if contains(presetFolders(iPreset).name,'Long')
                    preset{counter,1} = 'Long';
                else
                    preset{counter,1} = 'Short';
                end
            end
        end
        
    end
    
end
T = table(frameLink,cameraParamsLink,lutLink,serial,preset);
writetable(T,writeTablePath);
end