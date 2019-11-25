clear all
clc

atcPath = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2737\F9340833\ATC3\'; % '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2693\F9340026\Avishayexperiment\18-11\3.7.0.0 ATC\';
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
dataIn.calibParams.fwTable.nRowsRGB = 29;
dataIn.calibParams.warmUp.apdTempRange = [20 30];
% rerun
[dataRes.data, dataRes.calibPassed, dataRes.results, dataRes.metrics, dataRes.metricsWithTheoreticalFix, dataRes.Invalid_Frames] = Calibration.thermal.finalCalcAfterHeating(dataIn.data, dataIn.eepromRegs, dataIn.calibParams, dataIn.fprintff, dataIn.calib_dir, dataIn.runParams);
dataOut = load([atcFolder, 'finalCalcAfterHeating_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

