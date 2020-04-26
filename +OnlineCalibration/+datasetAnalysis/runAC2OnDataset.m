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
testSubName = '_runAC2_OnlyScaleY';
resultsHeadDir = 'X:\IVCAM2_calibration _testing\analysisResults';
sceneHeadDir = 'X:\IVCAM2_calibration _testing\AutoCalibration2_Scene&CB';
rng(1);
nAugPerScene = 5;
ind = 0;

goodScenesList = {};
badScenesList = {};
params.augmentRand01Number = rand(1);
params.augmentationMaxMovement = 4;
params.augmentOne = 1;
params.augmentationType = 'scaleDepthY';
params.AC2 = 1;


sceneDirs = dir(fullfile(sceneHeadDir,'scene*'));
for sc = 1:numel(sceneDirs)
    serialsDirs = dir(fullfile(sceneHeadDir,sceneDirs(sc).name,'F*'));
    for se = 1:numel(serialsDirs)
        presetDirs = dir(fullfile(sceneHeadDir,sceneDirs(sc).name,serialsDirs(se).name,'*_Preset'));
        for pr = 1:numel(presetDirs)
            resDirs = dir(fullfile(sceneHeadDir,sceneDirs(sc).name,serialsDirs(se).name,presetDirs(pr).name,'*x*'));
            for r = 1:numel(resDirs)
                sceneFullPath = fullfile(resDirs(r).folder,resDirs(r).name);
                for au = 1:nAugPerScene
                    try
                        disp(sceneFullPath)
                        seed = (randi(10000));
                        rng(seed);
                        sceneResults = OnlineCalibration.datasetAnalysis.runAC2FromDir(sceneFullPath,params);
                        if ~(isnan(sceneResults.uvErrPre) || isinf(sceneResults.uvErrPre))
                            ind = ind + 1;
                            results(ind) = sceneResults;
                            goodScenesList{numel(goodScenesList)+1} = sceneFullPath;
                        else
                            badScenesList{numel(goodScenesList)+1} = sceneFullPath;
                        end
                    catch e
                        badScenesList{numel(goodScenesList)+1} = sceneFullPath;
                        sceneFullPath
                        e.message
                        e.stack(1)
                    end
                end
            end
        end
    end
end


resultsSubDirName = fullfile(resultsHeadDir,[datestr(now,'yy_mmmm_dd___HH_MM'),testSubName]);
mkdir(resultsSubDirName);
resultsFileName = fullfile(resultsSubDirName,'results.mat');
% save(resultsFileName,'results','nAugPerScene')
save(resultsFileName,'results','nAugPerScene','goodScenesList','badScenesList')