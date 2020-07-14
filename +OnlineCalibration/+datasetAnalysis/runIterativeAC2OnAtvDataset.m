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

testSubName = '_iterativeFromAtvDivideAug';

resultsHeadDir = 'X:\IVCAM2_calibration _testing\analysisResults';
sceneHeadDir = 'X:\IVCAM2_calibration _testing\ATVs';
rng(4);
nAugPerScene = 1;
ind = 0;
indThermal = 0;

goodScenesList = {};
badScenesList = {};

params.augmentationMaxMovement = 10;
params.augMethod = 'dsmAndRotation';
params.AC2 = 1;
params.applyK2DSMFix = true;
params.rgbThermalFix = 1;
resultsSubDirName = fullfile(resultsHeadDir,[datestr(now,'yy_mmmm_dd___HH_MM'),testSubName]);
mkdirSafe(resultsSubDirName);
params.logOutFolder = resultsSubDirName;

serialsDirs = dir(fullfile(sceneHeadDir,'F*'));
for se = 1:numel(serialsDirs)
    atvDir = dir(fullfile(sceneHeadDir,serialsDirs(se).name,'ATV*'));
    cyclesDir = dir(fullfile(sceneHeadDir,serialsDirs(se).name,atvDir.name,'\Images\Thermal','cycle*'));
    for cy = 1:13:numel(cyclesDir)
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
                params.acData = OnlineCalibration.aux.defaultACTable();
                params.acData.flags = 1;
                params.acData.hFactor = ((rand*4-2)+100)/100;
                params.acData.vFactor = ((rand*4-2)+100)/100;
                sceneResults = OnlineCalibration.datasetAnalysis.runIterativeAC2FromDirAtvs(sceneFullPath,params);
                params.correctThermal = 1;
                sceneResultsThermal = OnlineCalibration.datasetAnalysis.runIterativeAC2FromDirAtvs(sceneFullPath,params);
                params.correctThermal = 0;
                sceneResults.randomSeed = seed;
                sceneResultsThermal.randomSeed = seed;
                if ~(isnan(sceneResults.uvErrPre) || isinf(sceneResults.uvErrPre))
                    ind = ind + 1;
                    results(ind) = sceneResults;
                    goodScenesList{numel(goodScenesList)+1} = sceneFullPath;
                else
                    badScenesList{numel(goodScenesList)+1} = sceneFullPath;
                end
                if ~(isnan(sceneResultsThermal.uvErrPre) || isinf(sceneResultsThermal.uvErrPre))
                    indThermal = indThermal + 1;
                    resultsThermal(indThermal) = sceneResultsThermal;
                    goodScenesListThermal{numel(goodScenesList)+1} = sceneFullPath;
                else
                    badScenesListThermal{numel(goodScenesList)+1} = sceneFullPath;
                end
%                 if any(isnan(sceneResults.features))
%                     warning('Found nan in SVM features');
%                 end
                fprintf('cost: ');
                fprintf('%g ',results(ind).desicionParams.initialCost);
                fprintf('-> %g ',results(ind).newCost);
                fprintf('\n');
                
                fprintf('uv: Pre->Post->PostThermal\n');
                fprintf('%2.2g ',results(ind).uvErrPre);
                fprintf('-> %2.2g \n',results(ind).uvErrPostK2DSM);
                fprintf('\n');
                fprintf('uv: %2.2g -> %2.2g       (Kz From P)        \n',results(ind).uvErrPre,results(ind).uvErrPostKzFromPOpt(1));
                
                
                fprintf('gid: Pre->Post->PostThermal\n');
                fprintf('%2.2g ',results(ind).gidPre);
                fprintf('-> %2.2g \n',results(ind).gidPostK2DSM);
                fprintf('\n');
                fprintf('gid: %2.2g -> %2.2g    (Kz From P)\n',results(ind).gidPre,results(ind).metricsPostKzFromP(1).gid);
                
                if sceneResults.validFixBySVM
                    fprintf('[v] Valid fix\n');
                else
                    fprintf('[x] Invalid fix\n');
                end
                
                fprintf('cost: ');
                fprintf('%g ',resultsThermal(indThermal).desicionParams.initialCost);
                fprintf('-> %g ',resultsThermal(indThermal).newCost);
                fprintf('\n');
                
                fprintf('uv: Pre->Post->PostThermal\n');
                fprintf('%2.2g ',resultsThermal(indThermal).uvErrPre);
                fprintf('-> %2.2g \n',resultsThermal(indThermal).uvErrPostK2DSM);
                fprintf('\n');
                fprintf('uv: %2.2g -> %2.2g       (Kz From P)        \n',resultsThermal(indThermal).uvErrPre,resultsThermal(indThermal).uvErrPostKzFromPOpt(1));
                
                
                fprintf('gid: Pre->Post->PostThermal\n');
                fprintf('%2.2g ',resultsThermal(indThermal).gidPre);
                fprintf('-> %2.2g \n',resultsThermal(indThermal).gidPostK2DSM);
                fprintf('\n');
                fprintf('gid: %2.2g -> %2.2g    (Kz From P)\n',resultsThermal(indThermal).gidPre,resultsThermal(indThermal).metricsPostKzFromP(1).gid);
                
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

resultsFileName = fullfile(resultsSubDirName,'results.mat');
% save(resultsFileName,'results','nAugPerScene')
save(resultsFileName,'results','resultsThermal','nAugPerScene','goodScenesList','badScenesList','goodScenesListThermal');
structFieldNames = fieldnames(results);
thinResultsStruct = struct();
thinResultsStructThermal = struct();
for k = 1:numel(structFieldNames)
    if contains(structFieldNames{k},'uv') || contains(structFieldNames{k},'gid') || contains(structFieldNames{k},'valid') || contains(structFieldNames{k},'Error') || contains(structFieldNames{k},'Seed')
        for ix = 1:numel(results)
            thinResultsStruct(ix).(structFieldNames{k}) = results(ix).(structFieldNames{k});
            thinResultsStructThermal(ix).(structFieldNames{k}) = resultsThermal(ix).(structFieldNames{k});
            thinResultsStruct(ix).captureHumT = results(ix).originalParams.captureHumT;
            thinResultsStructThermal(ix).captureHumT = resultsThermal(ix).originalParams.captureHumT;
            thinResultsStructThermal(ix).referenceTemp = resultsThermal(ix).originalParams.referenceTemp;
        end
    end
end
resultsTable = struct2table(thinResultsStruct);
resultsTableThermal = struct2table(thinResultsStructThermal);
writetable(resultsTable, fullfile(resultsSubDirName,'resultsTable.csv'));
writetable(resultsTableThermal, fullfile(resultsSubDirName,'resultsTableThermal.csv'))
