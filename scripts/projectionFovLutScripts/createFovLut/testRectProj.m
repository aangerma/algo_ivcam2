load("X:\Users\hila\F9280525\Algo1 3.09.1\mat_files\ROI_im.mat");
load('X:\Users\hila\F9280525\Algo1 3.09.1\mat_files\ROI_Calib_Calc_in.mat'); 
fprintff = @fprintf;
calibParams = xml2structWrapper('X:\Users\hila\F9280525\calibParamsVXGA.xml');

%calibParams.roi.extraMarginL = 1;
%calibParams.roi.extraMarginR = 1;
runParams.outputFolder = 'X:\Users\hila\F9280525\Algo1 3.09.1\AlgoInternal';
results=struct(); 
[roiRegs,results,fovData] = ROI_Calib_Calc_int(imUbias, calibParams, ROI_regs,runParams,results);