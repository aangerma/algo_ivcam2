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

testSubName = '_pThermalAnalysis';

resultsHeadDir = 'X:\IVCAM2_calibration _testing\analysisResults';
sceneHeadDir = 'X:\IVCAM2_calibration _testing\AutoCalibration2_Scene&CB';
rng(2);
nAugPerScene = 2;
ind = 0;

goodScenesList = {};
badScenesList = {};

params.augmentationMaxMovement = 10;
params.augMethod = 'dsmAndRotation';
params.AC2 = 1;
params.applyK2DSMFix = true;

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
                        params.augmentRand01Number = rand(1);
                        params.randVecForDsmAndRotation = rand(1,5);
%                         params.randVecForDsmAndRotation(1) = 0.5;
%                         params.randVecForDsmAndRotation(2) = 0.5;
                        sceneResults = OnlineCalibration.datasetAnalysis.runAC2FromDir(sceneFullPath,params);
                        if ~(isnan(sceneResults.uvErrPre) || isinf(sceneResults.uvErrPre))
                            ind = ind + 1;
                            results(ind) = sceneResults;
                            goodScenesList{numel(goodScenesList)+1} = sceneFullPath;
                        else
                            badScenesList{numel(goodScenesList)+1} = sceneFullPath;
                        end
                        if sceneResults.validFixBySVM
                            fprintf('[v] uv: %2.2g -> %2.2g -> %2.2g, gid: %2.2g -> %2.2g -> %2.2g\n',results(ind).uvErrPre,results(ind).uvErrPostKzFromPOpt,results(ind).uvErrPostK2DSMOpt,results(ind).metricsPre.gid,results(ind).metricsPostKzFromP.gid,results(ind).metricsPostK2DSM.gid);
                        else
                            fprintf('[x] uv: %2.2g -> %2.2g -> %2.2g, gid: %2.2g -> %2.2g -> %2.2g\n',results(ind).uvErrPre,results(ind).uvErrPostKzFromPOpt,results(ind).uvErrPostK2DSMOpt,results(ind).metricsPre.gid,results(ind).metricsPostKzFromP.gid,results(ind).metricsPostK2DSM.gid);
                        end
                        fprintf('DSM Scales XY: %2.2g,%2.2g\n',sceneResults.originalParams.dsmScaleX,sceneResults.originalParams.dsmScaleY)
                        dsmFixscales = (1-sceneResults.losScaling)*100;
                        fprintf('DSM Fix Scales: %2.2g,%2.2g\n',dsmFixscales(1),dsmFixscales(2));
                        kFixScales = sceneResults.newParamsKzFromP.Kdepth([1,5])./sceneResults.originalParams.Kdepth([1,5]);
                        fprintf('Kdepth Scales: %2.2g,%2.2g\n',(1-kFixScales(1))*100,(1-kFixScales(2))*100)
                        %                         fprintf('uvPre/PostP/PostPthermal/PostKzFromPthermal: %2.2g,%2.2g,%2.2g,%2.2g\n',results(ind).uvErrPre,results(ind).uvErrPostKzFromPOpt,results(ind).uvErrPostPthermalOpt,results(ind).uvErrPostKzFromPthermalOpt);
%                         fprintf('gidPre/Post/PosrThermal: %2.2g,%2.2g,%2.2g\n',results(ind).metricsPre.gid,results(ind).metricsPostKzFromP.gid,results(ind).metricsPostKzFromPthermal.gid);
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

%% Create a before and after table:
uvPre = [results.uvErrPre];
uvPost = [results.uvErrPostKzFromPOpt];
uvPostPthermal = [results.uvErrPostPthermalOpt];
uvPostKzPthermal = [results.uvErrPostKzFromPthermalOpt];

gidPre = [results.metricsPre];
gidPre = [gidPre.gid];
gidPost = [results.metricsPostKzFromP];
gidPost = [gidPost.gid];
gidPostPthermal = [results.metricsPostKzFromPthermal];
gidPostPthermal = [gidPostPthermal.gid];

A = [uvPre',uvPost',uvPostPthermal',uvPostKzPthermal',gidPre',gidPost',gidPostPthermal'];
pt = array2table(A, 'VariableNames', {'uvPre', 'uvPost','uvPostPthermal','uvPostKzPthermal','gidPre', 'gidPost','gidPostPthermal'})
writetable(pt, fullfile(resultsSubDirName,'uvPrePostGidPrePost.xls'))
