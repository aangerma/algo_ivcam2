clear all
clc

atcPath = 'W:\BIG PBS\HENG-3203\F0050019\ATC1\';
% atcPath = 'W:\BIG PBS\HENG-2837\F9340254\ATC3\';
% atcPath = 'W:\BIG PBS\HENG-2837\F9340423\ATC6\';
% atcPath = 'W:\BIG PBS\HENG-2837\F9340713\ATC16\';
% atcPath = 'W:\BIG PBS\HENG-2837\F9340789\ATC5\';
% atcPath = 'W:\BIG PBS\HENG-2837\F9340833\ATC6\';
% atcPath = 'W:\BIG PBS\HENG-2837\F9340876\ATC2\';
atcFolder = [atcPath, 'Matlab\mat_files\'];
calibDir = [atcPath, 'Matlab\AlgoInternal'];

%%

fprintf('running finalCalcAfterHeating...\n');
dataIn = load([atcFolder, 'finalCalcAfterHeating_in.mat']);
% eternal overrides
dataIn.calib_dir = calibDir;
dataIn.output_dir = 'D:/temp';
dataIn.runParams.outputFolder = dataIn.output_dir;
dataIn.fprintff = @fprintf;
% ad-hoc overrides
dataIn.calibParams = xml2structWrapper('../AlgoThermalCalibration/calibParams.xml');
% rerun
tic
[dataRes.data, dataRes.calibPassed, dataRes.results, dataRes.metrics, dataRes.metricsWithTheoreticalFix, dataRes.Invalid_Frames] = Calibration.thermal.finalCalcAfterHeating(dataIn.data, dataIn.eepromRegs, dataIn.calibParams, dataIn.fprintff, dataIn.calib_dir, dataIn.runParams);
toc
dataOut = load([atcFolder, 'finalCalcAfterHeating_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

