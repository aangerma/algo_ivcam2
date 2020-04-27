% The Test contains:
% Takes all scenes ( or a vector of indices in the list)
% For current set of hyperparams:
% For each scene:
% For each augmentation type:
% Offset and scale to depth images (
% Noise to all optimization params
% (Maybe) Noise of several pixels to each of the optimization params
% Perform the Auto Calibration  - on an option determined by a flag
% Save all indications that can help invalidate the scene (for later SVM training)
% Save a text file with the hyper params
% Save all indications that might help determine if the correction was good (UV errors) and the final params
% Save GID errors before and after
clear
close all
testSubName = '_bestVersionSoFar';
resultsHeadDir = 'X:\IVCAM2_calibration _testing\analysisResults';
scenesList = {'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1280X720)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\11';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\12';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\13';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\2';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\9';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 640X360)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 640X480)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 960X540)';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\11';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\12';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\13';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\15';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\2';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\3';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\4';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\9';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 480X640 (RGB 1920X1080)\7';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\1';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\12';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\13';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\14';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\15';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\2';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\3';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\4';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\6';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\7';'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\ShortRange 768X1024 (RGB 1920X1080)\9';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1280X720)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (640X360)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (640X480)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 480X640 (960X540)';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\13';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 480X640 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\13';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\2';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\ShortRange 768X1024 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1280X720)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (640X360)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (640X480)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 480X640 (960X540)';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\13';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\3';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\LongRange 768X1024 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 480X640 (1920X1080)\8';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\1';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\10';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\11';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\12';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\14';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\3';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\4';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\5';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\6';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\7';'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Snapshots\ShortRange 768X1024 (1920X1080)\8'};
rng(1);
nAugPerScene = 10;
% nAugPerScene = 1;
ind = 0;
for i = 1:numel(scenesList)
    scenePath = scenesList{i};
    for j = 1:nAugPerScene
        ind = ind + 1;
        params.cbGridSz = [9,13];
        if contains(scenePath,'25.2.20')
            params.targetType = 'checkerboard_Iv2A1';
        else
            params.targetType = 'checkerboard';
        end
        
        
        goodflow = 0;
        while ~goodflow
            goodflow = 1;
            try
                seed = (randi(10000));
                params.augmentRand01Number = rand(1);
                params.augmentationMaxMovement = 4;
                params.augmentOne = rand(1) < 0.5;
                params.useOriginalEdgeDetection = 0;
                params.inverseDistParams.norm = 1;
                fprintf('Scene %d Aug %d\n',i,j);
                rng(seed);
                results(ind,1) = OnlineCalibration.datasetAnalysis.runAC1FromDir(scenePath,params);
%                 params.useOriginalEdgeDetection = 0;
%                 params.inverseDistParams.norm = 2;
%                 fprintf('Scene %d Aug %d\n',i,j);
%                 rng(seed);
%                 results(ind,2) = OnlineCalibration.datasetAnalysis.runACFromDir(scenePath,params);
%                 fprintf('%2.2g %2.2g %2.2g %2.2g\n',results(ind,1).uvErrPre,results(ind,1).uvErrPostPOpt,results(ind,1).uvErrPostKdepthRTOpt,results(ind,2).uvErrPostKdepthRTOpt);
                fprintf('%2.2g %2.2g %2.2g \n',results(ind,1).uvErrPre,results(ind,1).uvErrPostPOpt,results(ind,1).uvErrPostPDecomposedOpt);

            catch e
                goodflow = 0;
            end
        end
%         resultsOld
%         resultsNew
    end
end

resultsSubDirName = fullfile(resultsHeadDir,[datestr(now,'yy_mmmm_dd___HH_MM'),testSubName]);
mkdir(resultsSubDirName);
resultsFileName = fullfile(resultsSubDirName,'results.mat');
% save(resultsFileName,'results','nAugPerScene')
save(resultsFileName,'results','nAugPerScene')