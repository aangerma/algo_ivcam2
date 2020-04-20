close all;
clear;

global sceneResults;
global runParams;
runParams.loadSingleScene = 1;
runParams.verbose = 0;
runParams.saveBins = 0;
runParams.ignoreSceneInvalidation = 1;
runParams.ignoreOutputInvalidation = 1;

resultsArray = cell(0);

scenesList = {'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1280X720)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\11';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\12';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\13';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\2';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\9';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 640X360)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 640X480)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 960X540)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\11';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\12';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\13';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\15';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\2';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\3';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\4';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\9';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\7';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\12';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\13';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\15';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\2';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\3';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\4';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\7';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\9';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1280X720)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (640X360)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (640X480)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (960X540)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\13';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\13';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1280X720)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (640X360)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (640X480)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (960X540)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\13';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\3';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\11';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\3';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\8'};

% subSets = {'19.2.20'};
for kk = 1:numel(scenesList)
    scenePath = scenesList{kk};%'X:\IVCAM2_calibration _testing\25.2.20';

    if contains(scenePath,'25.2.20')
        params.targetType = 'checkerboard_Iv2A1';
    else
        params.cbGridSz = [9,13];% not part of the optimization 
    end



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


save(sprintf('resultsArrayWithKdepthAndRotConstantW_%s.mat',date),'resultsArray');