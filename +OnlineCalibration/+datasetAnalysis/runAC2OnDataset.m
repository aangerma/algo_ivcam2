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
resultsHeadDir = 'X:\IVCAM2_calibration _testing\analysisResults';
scenesList = {'\\143.185.124.250\Users\Roma R\RnD\AutoCalibration2\Scene9\F0050045\Long_Preset\768x1024'};
rng(1);
nAugPerScene = 10;
ind = 0;
for i = 1:numel(scenesList)
    scenePath = scenesList{i};
    for j = 1:nAugPerScene
        ind = ind + 1;

        seed = (randi(10000));
        params.augmentRand01Number = rand(1);
        params.augmentationMaxMovement = 10;
        params.augmentOne = 1;
        params.augmentationType = 'scaleDepthX';
        params.AC2 = 1;
        fprintf('Scene %d Aug %d\n',i,j);
        rng(seed);
        results(ind) = OnlineCalibration.datasetAnalysis.runAC2FromDir(scenePath,params);
        fprintf('UV Pre|P|Krgb|Post = %2.2g|%2.2g|%2.2g|%2.2g\n',results(ind).uvErrPre,results(ind).uvErrPostPOpt,results(ind).uvErrPostKRTOpt,results(ind).uvErrPostKdepthRTOpt);
        fprintf('GID Pre/Post = %2.2g/%2.2g\n',results(ind).metricsPre.gid,results(ind).metricsPost.gid);
    end
end

resultsSubDirName = fullfile(resultsHeadDir,[datestr(now,'yy_mmmm_dd___HH_MM'),testSubName]);
mkdir(resultsSubDirName);
resultsFileName = fullfile(resultsSubDirName,'results.mat');
% save(resultsFileName,'results','nAugPerScene')
save(resultsFileName,'results','nAugPerScene')