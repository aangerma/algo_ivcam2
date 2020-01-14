clear all
clc

generalPath = [pwd, '\'];
curTestDir = 'ATC4\';

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

%% GenInitCalibTables_Calc
fprintf('\nrunning GenInitCalibTables_Calc... ');
dataIn = load([inputPath, 'GenInitCalibTables_Calc_in.mat']);
if isfield(dataIn, 'eepromBin')
    GenInitCalibTables_Calc(dataIn.calibParams, dataIn.outDir, dataIn.eepromBin)
else
    GenInitCalibTables_Calc(dataIn.calibParams, dataIn.outDir)
end
fprintf('\n')

%% DSM_CoarseCalib_Calc
fprintf('\nrunning DSM_CoarseCalib_Calc... ');
dataIn = load([inputPath, 'DSM_CoarseCalib_Calc_in.mat']);
dataRes.DSM_data = DSM_CoarseCalib_Calc(dataIn.angxRaw, dataIn.angyRaw, dataIn.calibParams);
dataOut = load([inputPath, 'DSM_CoarseCalib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% IR_DelayCalibCalc (initialization stage)
fprintf('\nrunning IR_DelayCalibCalc... ');
files = dir([inputPath, 'IR_DelayCalibCalc_init_in*']);
for iFile = 1:length(files)
    fprintf('\niteration #%d... ', iFile);
    dataIn = load(sprintf('%sIR_DelayCalibCalc_init_in%d.mat', inputPath, iFile));
    [dataRes.res, dataRes.delayIR, dataRes.im, dataRes.pixVar] = IR_DelayCalibCalc(dataIn.frameBytesUp, dataIn.frameBytesDown, dataIn.sz, dataIn.delay, dataIn.calibParams, dataIn.isFinalStage, dataIn.fResMirror);
    dataOut = load(sprintf('%sIR_DelayCalibCalc_init_out%d.mat', inputPath, iFile));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

%% Z_DelayCalibCalc (initialization stage)
fprintf('\nrunning Z_DelayCalibCalc... ');
files = dir([inputPath, 'Z_DelayCalibCalc_init_in*']);
for iFile = 1:length(files)
    fprintf('\ncycle #%d... ', iFile);
    dataIn = load(sprintf('%sZ_DelayCalibCalc_init_in%d.mat', inputPath, iFile));
    [dataRes.res, dataRes.delayZ, dataRes.im] = Z_DelayCalibCalc(dataIn.frameBytesUp, dataIn.frameBytesDown, dataIn.frameBytesBoth, dataIn.sz, dataIn.delay, dataIn.calibParams, dataIn.isFinalStage, dataIn.fResMirror);
    dataOut = load(sprintf('%sZ_DelayCalibCalc_init_out%d.mat', inputPath, iFile));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

%% TmptrDataFrame_Calc (heating stage)
fprintf('\nrunning TmptrDataFrame_Calc... ');
files = dir([inputPath, 'TmptrDataFrame_Calc_in*']);
for iFile = 1:length(files)-1
    fprintf('\ncycle #%d... ', iFile);
    dataIn = load(sprintf('%sTmptrDataFrame_Calc_in%d.mat', inputPath, iFile-1));
    [dataRes.finishedHeating, dataRes.calibPassed, dataRes.results, dataRes.metrics, dataRes.metricsWithTheoreticalFix, dataRes.Invalid_Frames] = TmptrDataFrame_Calc(dataIn.finishedHeating, dataIn.regs, dataIn.eepromRegs, dataIn.eepromBin, dataIn.FrameData, dataIn.sz, dataIn.frameBytes, dataIn.calibParams, dataIn.maxTime2Wait, dataIn.ctKillThr);
    dataOut = load(sprintf('%sTmptrDataFrame_Calc_out%d.mat', inputPath, iFile-1));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

%% IR_DelayCalibCalc (finalization stage)
fprintf('\nrunning IR_DelayCalibCalc... ');
files = dir([inputPath, 'IR_DelayCalibCalc_final_in*']);
for iFile = 1:length(files)
    fprintf('\niteration #%d... ', iFile);
    dataIn = load(sprintf('%sIR_DelayCalibCalc_final_in%d.mat', inputPath, iFile));
    [dataRes.res, dataRes.delayIR, dataRes.im, dataRes.pixVar] = IR_DelayCalibCalc(dataIn.frameBytesUp, dataIn.frameBytesDown, dataIn.sz, dataIn.delay, dataIn.calibParams, dataIn.isFinalStage, dataIn.fResMirror);
    dataOut = load(sprintf('%sIR_DelayCalibCalc_final_out%d.mat', inputPath, iFile));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

%% Z_DelayCalibCalc (finalization stage)
fprintf('\nrunning Z_DelayCalibCalc... ');
files = dir([inputPath, 'Z_DelayCalibCalc_final_in*']);
for iFile = 1:length(files)
    fprintf('\ncycle #%d... ', iFile);
    dataIn = load(sprintf('%sZ_DelayCalibCalc_final_in%d.mat', inputPath, iFile));
    [dataRes.res, dataRes.delayZ, dataRes.im] = Z_DelayCalibCalc(dataIn.frameBytesUp, dataIn.frameBytesDown, dataIn.frameBytesBoth, dataIn.sz, dataIn.delay, dataIn.calibParams, dataIn.isFinalStage, dataIn.fResMirror);
    dataOut = load(sprintf('%sZ_DelayCalibCalc_final_out%d.mat', inputPath, iFile));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

%% DSM_Calib_Calc
fprintf('\nrunning DSM_Calib_Calc... ');
dataIn = load([inputPath, 'DSM_Calib_Calc_in.mat']);
[dataRes.success, dataRes.DSM_data, dataRes.angxZO, dataRes.angyZO] = DSM_Calib_Calc(dataIn.frameBytes, dataIn.sz, dataIn.angxRawZOVec, dataIn.angyRawZOVec, dataIn.dsmregs_current, dataIn.calibParams);
dataOut = load([inputPath, 'DSM_Calib_Calc_out.mat']);
checkOutputEquality(dataOut, dataRes)
fprintf('\n')

%% TmptrDataFrame_Calc (final stage)
fprintf('\nrunning TmptrDataFrame_Calc... ');
files = dir([inputPath, 'TmptrDataFrame_Calc_in*']);
for iFile = length(files)
    fprintf('\ncycle #%d... ', iFile);
    dataIn = load(sprintf('%sTmptrDataFrame_Calc_in%d.mat', inputPath, iFile-1));
    [dataRes.finishedHeating, dataRes.calibPassed, dataRes.results, dataRes.metrics, dataRes.metricsWithTheoreticalFix, dataRes.Invalid_Frames] = TmptrDataFrame_Calc(dataIn.finishedHeating, dataIn.regs, dataIn.eepromRegs, dataIn.eepromBin, dataIn.FrameData, dataIn.sz, dataIn.frameBytes, dataIn.calibParams, dataIn.maxTime2Wait, dataIn.ctKillThr);
    dataOut = load(sprintf('%sTmptrDataFrame_Calc_out%d.mat', inputPath, iFile-1));
    checkOutputEquality(dataOut, dataRes)
end
fprintf('\n')

