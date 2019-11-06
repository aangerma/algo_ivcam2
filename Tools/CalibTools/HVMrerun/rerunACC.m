clear all
clc

generalPath = 'X:\Users\syaeli\Work\Code\algo_ivcam2\Tools\CalibTools\HVMrerun\';
curTestDir = 'ACC27\';

inputPath = [generalPath, curTestDir, 'Matlab\mat_files\'];
capturesPath = [generalPath, curTestDir, 'Images\'];

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
if isfield(dataIn, 'fprintff')
    [dataRes.calibParams , dataRes.result] = cal_init(dataIn.output_dir, dataIn.calib_dir, dataIn.calib_params_fn, dataIn.save_input_flag, dataIn.save_internal_input_flag, dataIn.save_output_flag, dataIn.fprintff);
else
    [dataRes.calibParams , dataRes.result] = cal_init(dataIn.output_dir, dataIn.calib_dir, dataIn.calib_params_fn, dataIn.debug_log_f, dataIn.verbose, dataIn.save_input_flag, dataIn.save_internal_input_flag, dataIn.save_output_flag, dataIn.dummy_output_flag);
end
dataOut = load([inputPath, 'cal_init_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% Preset_Short_Calib_Calc
fprintf('\nrunning Preset_Short_Calib_Calc... ');
dataIn = load([inputPath, 'Preset_Short_Calib_Calc_in.mat']);
ind = strfind(dataIn.InputPath, curTestDir);
dataIn.InputPath = [generalPath, dataIn.InputPath(ind:end)];
[dataRes.minRangeScaleModRef, dataRes.ModRefDec] = Preset_Short_Calib_Calc(dataIn.InputPath, dataIn.LaserPoints, dataIn.maxMod_dec, dataIn.sz, dataIn.calibParams);
dataOut = load([inputPath, 'Preset_Short_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% DFZ_Calib_Calc
fprintf('\nrunning DFZ_Calib_Calc... ');
dataIn = load([inputPath, 'DFZ_Calib_Calc_in.mat']);
ind = strfind(dataIn.InputPath, curTestDir);
dataIn.InputPath = [generalPath, dataIn.InputPath(ind:end)];
[dataRes.dfzRegs, dataRes.results, dataRes.calibPassed] = DFZ_Calib_Calc(dataIn.InputPath, dataIn.calibParams, dataIn.DFZ_regs);
dataOut = load([inputPath, 'DFZ_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% ROI_Calib_Calc
fprintf('\nrunning ROI_Calib_Calc... ');
dataIn = load([inputPath, 'ROI_Calib_Calc_in.mat']);
ind = strfind(dataIn.InputPath, curTestDir);
dataIn.InputPath = [generalPath, dataIn.InputPath(ind:end)];
[dataRes.roiRegs, dataRes.results, dataRes.fovData] = ROI_Calib_Calc(dataIn.InputPath, dataIn.calibParams, dataIn.ROIregs, dataIn.results, dataIn.eepromBin);
dataOut = load([inputPath, 'ROI_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% END_calib_Calc
fprintf('\nrunning END_calib_Calc... ');
dataIn = load([inputPath, 'END_calib_Calc_in.mat']);
ind = strfind(dataIn.fnCalib, curTestDir);
dataIn.fnCalib = [generalPath, dataIn.fnCalib(ind:end)];
[dataRes.results, dataRes.regs, dataRes.luts] = END_calib_Calc(dataIn.delayRegs, dataIn.dsmregs, dataIn.roiRegs, dataIn.dfzRegs, dataIn.results, dataIn.fnCalib, dataIn.calibParams, dataIn.undist_flag, dataIn.configurationFolder, dataIn.eepromRegs, dataIn.eepromBin, dataIn.afterThermalCalib_flag);
dataOut = load([inputPath, 'END_calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% RtdOverAngXStateValues_Calib_Calc
fprintf('\nrunning RtdOverAngXStateValues_Calib_Calc... ');
dataIn = load([inputPath, 'RtdOverAngXStateValues_Calib_Calc_in.mat']);
[dataRes.delayVecNoChange, dataRes.delayVecSteps] = RtdOverAngXStateValues_Calib_Calc(dataIn.calibParams, dataIn.regs);
dataOut = load([inputPath, 'RtdOverAngXStateValues_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% RtdOverAngX_Calib_Calc
fprintf('\nrunning RtdOverAngX_Calib_Calc... ');
dataIn = load([inputPath, 'RtdOverAngX_Calib_Calc_in.mat']);
ind = strfind(dataIn.inputPath, curTestDir);
dataIn.inputPath = [generalPath, dataIn.inputPath(ind:end)];
[dataRes.tablefn] = RtdOverAngX_Calib_Calc(dataIn.inputPath, dataIn.calibParams, dataIn.regs, dataIn.luts);
dataOut = load([inputPath, 'RtdOverAngX_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% Preset_Long_Calib_Calc
fprintf('\nrunning Preset_Long_Calib_Calc (state 1)... ');
dataIn = load([inputPath, 'Preset_Long_Calib_Calc_state1_in.mat']);
ind = strfind(dataIn.InputPath, curTestDir);
dataIn.InputPath = [generalPath, dataIn.InputPath(ind:end)];
[dataRes.maxRangeScaleModRef, dataRes.maxFillRate, dataRes.targetDist] = Preset_Long_Calib_Calc(dataIn.InputPath, dataIn.cameraInput, dataIn.LaserPoints, dataIn.maxMod_dec, dataIn.calibParams);
dataOut = load([inputPath, 'Preset_Long_Calib_Calcstate1_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% Preset_Long_Calib_Calc
fprintf('\nrunning Preset_Long_Calib_Calc (state 2)... ');
dataIn = load([inputPath, 'Preset_Long_Calib_Calc_state2_in.mat']);
ind = strfind(dataIn.InputPath, curTestDir);
dataIn.InputPath = [generalPath, dataIn.InputPath(ind:end)];
[dataRes.maxRangeScaleModRef, dataRes.maxFillRate, dataRes.targetDist] = Preset_Long_Calib_Calc(dataIn.InputPath, dataIn.cameraInput, dataIn.LaserPoints, dataIn.maxMod_dec, dataIn.calibParams);
dataOut = load([inputPath, 'Preset_Long_Calib_Calcstate2_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% PresetsAlignment_Calib_Calc
fprintf('\nrunning PresetsAlignment_Calib_Calc... ');
dataIn = load([inputPath, 'PresetsAlignment_Calib_Calc_in.mat']);
ind = strfind(dataIn.InputPath, curTestDir);
dataIn.InputPath = [generalPath, dataIn.InputPath(ind:end)];
[dataRes.results] = PresetsAlignment_Calib_Calc(dataIn.InputPath, dataIn.calibParams, dataIn.res, dataIn.z2mm);
dataOut = load([inputPath, 'PresetsAlignment_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% UpdateShortPresetRtdDiff_Calib_Calc
fprintf('\nrunning UpdateShortPresetRtdDiff_Calib_Calc... ');
dataIn = load([inputPath, 'UpdateShortPresetRtdDiff_Calib_Calc_in.mat']);
[dataRes.success] = UpdateShortPresetRtdDiff_Calib_Calc(dataIn.results);
dataOut = load([inputPath, 'UpdateShortPresetRtdDiff_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% GeneratePresetsTable_Calib_Calc
fprintf('\nrunning GeneratePresetsTable_Calib_Calc... ');
dataIn = load([inputPath, 'GeneratePresetsTable_Calib_Calc_in.mat']);
[dataRes.presetsTableFullPath] = GeneratePresetsTable_Calib_Calc(dataIn.calibParams);
dataOut = load([inputPath, 'GeneratePresetsTable_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% RGB_Calib_Calc
fprintf('\nrunning RGB_Calib_Calc... ');
dataIn = load([inputPath, 'RGB_Calib_Calc_in.mat']);
ind = strfind(dataIn.InputPath, curTestDir);
dataIn.InputPath = [generalPath, dataIn.InputPath(ind:end)];
[dataRes.rgbPassed, dataRes.rgbTable, dataRes.results] = RGB_Calib_Calc(dataIn.InputPath, dataIn.calibParams, dataIn.irImSize, dataIn.Kdepth, dataIn.z2mm);
dataOut = load([inputPath, 'RGB_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')


