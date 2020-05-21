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

testSubName = '_iterativeFromAtv';

resultsHeadDir = 'X:\IVCAM2_calibration _testing\analysisResults';
sceneHeadDir = 'X:\IVCAM2_calibration _testing\ATVs';
rng(4);
nAugPerScene = 1;
ind = 0;

goodScenesList = {};
badScenesList = {};

params.augmentationMaxMovement = 10;
params.augMethod = 'dsmAndRotation';
params.AC2 = 1;
params.applyK2DSMFix = true;
params.rgbThermalFix = 1;

serialsDirs = dir(fullfile(sceneHeadDir,'F*'));
for se = 1:numel(serialsDirs)
    atvDir = dir(fullfile(sceneHeadDir,serialsDirs(se).name,'ATV*'));
    cyclesDir = dir(fullfile(sceneHeadDir,serialsDirs(se).name,atvDir.name,'\Images\Thermal','cycle*'));
    for cy = 1:numel(cyclesDir)
        sceneFullPath = fullfile(sceneHeadDir,serialsDirs(se).name,atvDir.name,['\Images\Thermal\cycle' num2str(cy-1)]);
        for au = 1:nAugPerScene
            try
                disp(sceneFullPath)
                seed = (randi(10000));
                rng(seed);
                params.augmentRand01Number = rand(1);
                params.randVecForDsmAndRotation = rand(1,5);
                %                         params.randVecForDsmAndRotation(3:5) = 0;
                if params.augmentationMaxMovement == 0
                    params.augmentRand01Number = 0;
                    params.randVecForDsmAndRotation = zeros(1,5);
                    params.randVecForDsmAndRotation(1) = 0.5;
                    params.randVecForDsmAndRotation(2) = 0.5;
                end
                sceneResults = OnlineCalibration.datasetAnalysis.runIterativeAC2FromDirAtv(sceneFullPath,params);
                sceneResults.randomSeed = seed;
                if ~(isnan(sceneResults.uvErrPre) || isinf(sceneResults.uvErrPre))
                    ind = ind + 1;
                    results(ind) = sceneResults;
                    goodScenesList{numel(goodScenesList)+1} = sceneFullPath;
                else
                    badScenesList{numel(goodScenesList)+1} = sceneFullPath;
                end
                if any(isnan(sceneResults.features))
                    warning('Found nan in SVM features');
                end
                fprintf('cost: ');
                fprintf('%g ',results(ind).desicionParams.initialCost);
                fprintf('-> %g ',results(ind).newCost);
                fprintf('\n');
                
                fprintf('uv: ');
                fprintf('%2.2g ',results(ind).uvErrPre);
                fprintf('-> %2.2g ',results(ind).uvErrPostK2DSM);
                fprintf('\n');
                fprintf('uv: %2.2g -> %2.2g       (Kz From P)        \n',results(ind).uvErrPre,results(ind).uvErrPostKzFromPOpt(1));
                
                
                fprintf('gid: ');
                fprintf('%2.2g ',results(ind).gidPre);
                fprintf('-> %2.2g ',results(ind).gidPostK2DSM);
                fprintf('\n');
                fprintf('gid: %2.2g -> %2.2g    (Kz From P)\n',results(ind).gidPre,results(ind).metricsPostKzFromP(1).gid);
                
                if sceneResults.validFixBySVM
                    fprintf('[v] Valid fix\n');
                else
                    fprintf('[x] Invalid fix\n');
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
