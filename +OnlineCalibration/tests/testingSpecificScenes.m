close all;
clear;
pathDir = 'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\6';
pathDir = 'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 1920X1080)\2';
pathDir = 'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 768X1024 (RGB 1920X1080)\1';
% params.targetType = 'checkerboard_Iv2A1';
params.cbGridSz = [9,13];% not part of the optimization 



global runParams;
global sceneResults;


runParams.loadSingleScene = 1;
runParams.verbose = 0;
runParams.saveBins = 0;
runParams.ignoreSceneInvalidation = 1;
runParams.ignoreOutputInvalidation = 1;



runOnlineCalibrationFromDir(pathDir,params);
sceneResults