close all;
clear all;

dirPath = 'X:\IVCAM2_calibration _testing\20.2.20';%'X:\IVCAM2_calibration _testing\25.2.20';

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
params.inverseDistParams.alpha = 1/3;
params.inverseDistParams.gamma = 0.98;
params.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
params.gradITh = 3.5; % Ignore pixels with IR grad of less than this
params.gradZTh = 25; % Ignore pixels with Z grad of less than this
params.gradZMax = 1000; 
% params.derivVar = 'P';
params.maxStepSize = 1;%1;
params.tau = 0.5;
params.controlParam = 0.5;
params.minStepSize = 1e-5;
params.maxBackTrackIters = 50;
params.minRgbPmatDelta = 1e-5;
params.minCostDelta = 1;
params.maxOptimizationIters = 50;
params.zeroLastLineOfPGrad = 1;
params.constLastLineOfP = 0;
% params.rgbPmatNormalizationMat = [0.3242,     0.4501,    0.2403,   359.3750;      0.3643,     0.5074      0.2689     402.3438;      0.0029     0.0040     0.0021     3.2043];
% params.rgbPmatNormalizationMat = [0.35682896, 0.26685065,1.0236474,0.00068233482; 0.35521242, 0.26610452, 1.0225836, 0.00068178622; 410.60049, 318.23358, 1205.4570, 0.80363423];
params.rgbPmatNormalizationMat = [0.35369244,0.26619774,1.0092601,0.00067320449;0.35508525,0.26627505,1.0114580,0.00067501375;414.20557,313.34106,1187.3459,0.79157025];
params.KrgbMatNormalizationMat = [0.35417202,0.26565930,1.0017655;0.35559174,0.26570305,1.0066491;409.82886,318.79565,1182.6952];
params.RnormalizationParams = [1508.9478;1604.9430;649.38434];
params.TmatNormalizationMat = [0.91300839;0.91698289;0.43305457];

params.edgeThresh4logicIm = 0.1;
params.seSize = 3;
params.moveThreshPixVal = 20;
params.moveGaussSigma = 1;
params.maxXYMovementPerIteration = [10,2,2];
params.maxXYMovementFromOrigin = 20;
params.numSectionsV = 2;
params.numSectionsH = 2;
params.edgeDistributMinMaxRatio = 0.005;
params.minWeightedEdgePerSectionDepth = 50;
params.minWeightedEdgePerSectionRgb = 0.05;

%%
dirData = dir(dirPath);

for ixUnit = 1:numel(dirData)
    if ~contains(dirData(ixUnit).name, 'F')
        continue;
    end
    unitSN = dirData(ixUnit).name;
    disp(['Running analysis on unit ' unitSN]);
    snapshotsFld = fullfile(dirPath,dirData(ixUnit).name,'Videos');
    dirDataPerUnit = dir(snapshotsFld);
    for ixSnap = 1:numel(dirDataPerUnit)
        if ~contains(dirDataPerUnit(ixSnap).name, 'Range')
            continue;
        end
        scenePath = fullfile(dirPath,dirData(ixUnit).name,'Videos',dirDataPerUnit(ixSnap).name);
        scenePathData = dir(scenePath);
        if all([scenePathData.isdir])
            for ixSubFldr = 1:numel(scenePathData)
                try
                if isnan(str2double(scenePathData(ixSubFldr).name))
                    continue;
                end
                disp(['Folder Path ' fullfile(scenePath,scenePathData(ixSubFldr).name)]);
                runOnlineCalibrationFromDir(fullfile(scenePath,scenePathData(ixSubFldr).name),params);
                catch e
                    disp([e.identifier ' '  e.message 'in ' fullfile(scenePath,scenePathData(ixSubFldr).name) ', continuing to next folder...']);
                    continue;
                end
            end
        else
            disp(['Folder Path ' scenePath]);
            runOnlineCalibrationFromDir(scenePath,params);
        end
    end
    
end