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

testSubName = '_luts_AutoCalibration2_Scene&CB';
resultsHeadDir = 'X:\IVCAM2_calibration _testing\analysisResults';
sceneHeadDir = 'X:\IVCAM2_calibration _testing\AutoCalibration3_Scene&CB_aged';
rng(4);
ind = 0;

params.factorsVec = 0.98:0.002:1.02;

sceneDirs = dir(fullfile(sceneHeadDir,'scene*'));
for sc = 1:numel(sceneDirs)
    serialsDirs = dir(fullfile(sceneHeadDir,sceneDirs(sc).name,'F*'));
    for se = 1:numel(serialsDirs)
        presetDirs = dir(fullfile(sceneHeadDir,sceneDirs(sc).name,serialsDirs(se).name,'*_Preset'));
        for pr = 1:numel(presetDirs)
            resDirs = dir(fullfile(sceneHeadDir,sceneDirs(sc).name,serialsDirs(se).name,presetDirs(pr).name,'*x*'));
            for r = 1:numel(resDirs)
                sceneFullPath = fullfile(resDirs(r).folder,resDirs(r).name);
                disp(sceneFullPath)
                ind = ind + 1;
                lutResults(ind) = OnlineCalibration.datasetAnalysis.calcLutFromDir(sceneFullPath,params);
                
            end
        end
    end
end

resultsSubDirName = fullfile(resultsHeadDir,[datestr(now,'yy_mmmm_dd___HH_MM'),testSubName]);
mkdirSafe(resultsSubDirName);
resultsFileName = fullfile(resultsSubDirName,'lutResults.mat');
save(resultsFileName,'lutResults')


