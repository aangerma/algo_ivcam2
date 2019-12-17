%% Set globals
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0 - Copy\Matlab\mat_files\cal_init_in.mat');
calib_dir = 'X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0 - Copy\Matlab\AlgoInternal';
output_dir = 'X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0 - Copy\Matlab';
runParams.outputFolder = output_dir;
fprintff = @fprintf;
calib_params_fn = 'X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0 - Copy\Matlab\AlgoInternal\calibParams.ACC.xml';


[calibParams, result] = cal_init(output_dir, calib_dir, calib_params_fn, 1, 1, 1, 1, fprintff);


%% 

load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0 - Copy\Matlab\mat_files\END_calib_Calc_in.mat');
fnCalib = 'X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0 - Copy\Matlab\AlgoInternal\calib.csv';
configurationFolder = calib_dir;
roiRegs.FRMW.calMarginB = int16(-50);
roiRegs.FRMW.calMarginT = int16(-50);
roiRegs.FRMW.calMarginL = int16(-50);
roiRegs.FRMW.calMarginR = int16(-50);
[results, regs, luts] = END_calib_Calc(roiRegs, dfzRegs, agingRegs, results, fnCalib, calibParams, undist_flag, configurationFolder, eepromRegs, eepromBin);

hw = HWinterface;
hw.burnCalibConfigFiles('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0 - Copy\Matlab\calibOutputFiles')