% close all;
clear;

global runParams;

global sceneResults;

runParams.loadSingleScene = 0;
runParams.verbose = 0;
runParams.saveBins = 0;
runParams.ignoreSceneInvalidation = 1;
runParams.ignoreOutputInvalidation = 1;

resultsArray = cell(0);
params.augmentationType = 'scaleDepthX_scaleDepthY';

headPath = 'C:\Users\mkiperwa\Downloads\movies\';%'X:\IVCAM2_calibration _testing';
subSets =  {'25.3.20'};%{'19.2.20','20.2.20','25.2.20'};{'30.3.20'};
params.fileJump = 90;
mkdirSafe(fullfile(headPath,'results'));
% subSets = {'19.2.20'};
for kk = 1:numel(subSets)
    dirPath = fullfile(headPath,subSets{kk});%'X:\IVCAM2_calibration _testing\25.2.20';

    % intrinsicsExtrinsicsPath = fullfile(sceneDir,'camerasParams.mat');
    %%
    % Load data of scene 
    % load(intrinsicsExtrinsicsPath);
    % Define hyperparameters
    strSplitted = strsplit(dirPath,'\');
%     if strcmp(strSplitted{end},'25.2.20')
%         params.targetType = 'checkerboard_Iv2A1';
%     else
%         params.cbGridSz = [9,13];% not part of the optimization 
%     end
    if contains(dirPath,'25.2.20')
        params.targetType = 'checkerboard_Iv2A1';
    else
        params.targetType = 'checkerboard';
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
        contCount = 0;
        for ixSnap = 1:numel(dirDataPerUnit)
            if ~contains(dirDataPerUnit(ixSnap).name, 'Range')
                contCount = contCount + 1;
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
                    currentResults = runACFromDirOverTime(sceneFullPath,params);
                    save(fullfile(headPath,'results',sprintf('results_%s_%s.mat',num2str(ixSubFldr-contCount),datestr(now,'mm-dd-yyyy HH-MM'))),'currentResults');
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
                currentResults = runACFromDirOverTime(scenePath,params);
                save(fullfile(headPath,'results',sprintf('results_%s.mat',datestr(now,'mm-dd-yyyy HH-MM'))),'currentResults');
                resultsArray{numel(resultsArray)} = sceneResults;
                sceneResults
            end
        end

    end
end
