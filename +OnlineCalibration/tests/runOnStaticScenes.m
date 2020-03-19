close all;
clear;

global runParams;

global sceneResults;

runParams.loadSingleScene = 1;
runParams.verbose = 0;
runParams.saveBins = 0;
runParams.ignoreSceneInvalidation = 1;
runParams.ignoreOutputInvalidation = 1;

resultsArray = cell(0);


headPath = 'X:\IVCAM2_calibration _testing';
subSets = {'19.2.20','20.2.20','25.2.20'};

% subSets = {'19.2.20'};
for kk = 1:numel(subSets)
    dirPath = fullfile(headPath,subSets{kk});%'X:\IVCAM2_calibration _testing\25.2.20';

    % intrinsicsExtrinsicsPath = fullfile(sceneDir,'camerasParams.mat');
    %%
    % Load data of scene 
    % load(intrinsicsExtrinsicsPath);
    % Define hyperparameters
    strSplitted = strsplit(dirPath,'\');
    if strcmp(strSplitted{end},'25.2.20')
        params.targetType = 'checkerboard_Iv2A1';
    else
        params.cbGridSz = [9,13];% not part of the optimization 
    end

    %%
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
                    sceneResults = struct;

                    try
                    if isnan(str2double(scenePathData(ixSubFldr).name))
                        continue;
                    end
                    sceneFullPath =  fullfile(scenePath,scenePathData(ixSubFldr).name);
                    disp(['Folder Path ' sceneFullPath]);
                    sceneResults.sceneFullPath = sceneFullPath;
                    resultsArray{numel(resultsArray) + 1} = sceneResults;
                    runOnlineCalibrationFromDir(sceneFullPath,params);

                    catch e
                        disp([e.identifier ' '  e.message 'in ' fullfile(scenePath,scenePathData(ixSubFldr).name) ', continuing to next folder...']);
                        continue;
                    end
                    resultsArray{numel(resultsArray)} = sceneResults;
                    sceneResults
                end
            else
                disp(['Folder Path ' scenePath]);
                sceneResults = struct;
                sceneResults.sceneFullPath = scenePath;
                resultsArray{numel(resultsArray) + 1} = sceneResults;
                runOnlineCalibrationFromDir(scenePath,params);
                resultsArray{numel(resultsArray)} = sceneResults;
                sceneResults
            end
        end

    end
end


save(sprintf('resultsArray_%s.mat',date),'resultsArray');