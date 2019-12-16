% load('X:\Users\mkiperwa\projection\F557\ACC\Matlab\mat_files\ROI_Calib_Calc_in.mat'); 
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\ROI_Calib_Calc_in.mat'); 

% calibParams = xml2structWrapper('X:\Users\hila\L515\projectionByRoiLut\F9280525\calibParamsVXGA.xml');

%calibParams.roi.extraMarginL = 1;
%calibParams.roi.extraMarginR = 1;
% runParams.outputFolder = 'X:\Users\hila\L515\projectionByRoiLut\F9280525\Algo1 3.09.1\AlgoInternal';
global g_calib_dir
% g_calib_dir = 'X:\Users\mkiperwa\projection\F557\ACC\Matlab\AlgoInternal';
g_calib_dir = 'X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal';
runParams.outputFolder = 'X:\Users\mkiperwa\runningFolder\F9340557';
results=struct(); 
% [roiRegs,results,fovData] = ROI_Calib_Calc_int(imUbias, calibParams, ROI_regs,runParams,results,fprintff);
[roiRegs, results, fovData] = ROI_Calib_Calc(frameBytes, calibParams, ROIregs, results, eepromBin);
