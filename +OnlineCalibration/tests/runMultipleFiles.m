close all;
clear all;

dirPath = 'X:\IVCAM2_calibration _testing\20.2.20';


dirData = dir(dirPath);

for ixUnit = 1:numel(dirData)
    if ~contains(dirData(ixUnit).name, 'F')
        continue;
    end
    unitSN = dirData(ixUnit).name;
    disp(['Running analysis on unit ' unitSN]);
    snapshotsFld = fullfile(dirPath,dirData(ixUnit).name,'Snapshots');
    dirDataPerUnit = dir(snapshotsFld);
    for ixSnap = 1:numel(dirDataPerUnit)
        if ~contains(dirDataPerUnit(ixSnap).name, 'Range')
            continue;
        end
        scenePath = fullfile(dirPath,dirData(ixUnit).name,'Snapshots',dirDataPerUnit(ixSnap).name);
        scenePathData = dir(scenePath);
        if all([scenePathData.isdir])
            for ixSubFldr = 1:numel(scenePathData)
                try
                if isnan(str2double(scenePathData(ixSubFldr).name))
                    continue;
                end
                disp(['Folder Path ' fullfile(scenePath,scenePathData(ixSubFldr).name)]);
                runOnlineCalibrationFromDir(fullfile(scenePath,scenePathData(ixSubFldr).name));
                catch e
                    disp([e.identifier ' '  e.message 'in ' fullfile(scenePath,scenePathData(ixSubFldr).name) ', continuing to next folder...']);
                    continue;
                end
            end
        else
            disp(['Folder Path ' scenePath]);
            runOnlineCalibrationFromDir(scenePath);
        end
    end
    
end