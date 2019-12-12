%%
% Load unit data:
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\ROI_Calib_Calc_in.mat')
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\cal_init_in.mat')
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal\tpsUndistModel.mat')

%%
fw = Pipe.loadFirmware('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal');
[regs,luts] = fw.get;
hw = HWinterface;
verbose = 1; 
topMarginPix = 100;
bottomMarginPix = 100;
totRange = 4095;
anglesRng = 2047;
rectY = [-10,458];
rectX = [0,1024];

%%