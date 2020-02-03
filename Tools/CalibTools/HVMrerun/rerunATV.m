clear all
clc

generalPath = [pwd, '\'];
curTestDir = 'ACC32\';

inputPath = [generalPath, curTestDir, 'Matlab\mat_files\'];

%% cal_init
fprintf('\nrunning cal_init... ');
dataIn = load([inputPath, 'cal_init_in.mat']);
ind = strfind(dataIn.output_dir, curTestDir);
dataIn.output_dir = [generalPath, dataIn.output_dir(ind:end)];
dataIn.calib_params_fn = [generalPath, dataIn.calib_params_fn(ind:end)];
dataIn.calib_dir = [generalPath, dataIn.calib_dir(ind:end)];
dataIn.save_input_flag = 0;
dataIn.save_internal_input_flag = 0;
dataIn.save_output_flag = 0;
dataIn.skip_thermal_iterations_save = 1;
if isfield(dataIn, 'fprintff')
    [dataRes.calibParams, dataRes.result] = cal_init(dataIn.output_dir, dataIn.calib_dir, dataIn.calib_params_fn, dataIn.save_input_flag, dataIn.save_internal_input_flag, dataIn.save_output_flag, dataIn.skip_thermal_iterations_save, dataIn.fprintff);
else
    [dataRes.calibParams, dataRes.result] = cal_init(dataIn.output_dir, dataIn.calib_dir, dataIn.calib_params_fn, dataIn.save_input_flag, dataIn.save_internal_input_flag, dataIn.save_output_flag, dataIn.skip_thermal_iterations_save);
end
dataOut = load([inputPath, 'cal_init_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% ThermalValidationDataFrame_Calc (heating stage)
fprintf('\nrunning ThermalValidationDataFrame_Calc... ');
files = dir([inputPath, 'ThermalValidationDataFrame_Calc_in*']);
for iFile = 1:length(files)-1
    fprintf('\ncycle #%d... ', iFile);
    dataIn = load(sprintf('%sThermalValidationDataFrame_Calc_in%d.mat', inputPath, iFile-1));
    [dataRes.finishedHeating, dataRes.calibPassed, dataRes.results] = ThermalValidationDataFrame_Calc(dataIn.finishedHeating, dataIn.unitData, dataIn.FrameData, dataIn.sz, dataIn.frameBytes, dataIn.calibParams);
    dataOut = load(sprintf('%sThermalValidationDataFrame_Calc_out%d.mat', inputPath, iFile-1));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

%% ThermalValidationDataFrame_Calc (final stage)
fprintf('\nrunning ThermalValidationDataFrame_Calc... ');
files = dir([inputPath, 'ThermalValidationDataFrame_Calc_in*']);
for iFile = length(files)
    fprintf('\ncycle #%d... ', iFile);
    dataIn = load(sprintf('%sThermalValidationDataFrame_Calc_in%d.mat', inputPath, iFile-1));
    [dataRes.finishedHeating, dataRes.calibPassed, dataRes.results] = ThermalValidationDataFrame_Calc(dataIn.finishedHeating, dataIn.unitData, dataIn.FrameData, dataIn.sz, dataIn.frameBytes, dataIn.calibParams);
    dataOut = load(sprintf('%sThermalValidationDataFrame_Calc_out%d.mat', inputPath, iFile-1));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

