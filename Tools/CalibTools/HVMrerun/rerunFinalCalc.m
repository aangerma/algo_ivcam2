clear all
clc

%atcPath = 'W:\BIG PBS\HENG-2820\20-60 linear non gradual\F9340536\ATC 20-60\';
%atcPath = 'W:\BIG PBS\HENG-2820\F9340068\ATC 20-60 polynomial ex\';
%atcPath = 'W:\BIG PBS\HENG-2820\20-60 linear non gradual\F9340536\ATC 20-60\';
%atcPath = 'W:\BIG PBS\HENG-2820\20-60 linear non gradual\F9340833\';
%atcPath = 'W:\BIG PBS\HENG-2820\20-60 linear non gradual\F9340026\ATC9\';
atcPath = 'W:\BIG PBS\HENG-2820\New_DLL_20-60\F9340284\ATC 20-60\ATC13\';
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

