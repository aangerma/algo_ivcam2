% ROI warp
load('C:\temp\unitCalib\F9140938\PC32\mat_files\ROI_Calib_Calc_in.mat');
InputPath = 'C:\Users\tbenshab\AppData\Local\Temp\ROI';
results = [];
[roiRegs,results,fovData] = ROI_Calib_Calc(InputPath, calibParams, ROIregs,results)

% DFZ Preset
%% cal init function 
output_dir = fullfile(ivcam2tempdir,'unit_test','output_dir');
mkdirSafe(output_dir);
calib_dir = fullfile(ivcam2root,'CompiledAPI','calib_dir');
calib_params_fn =  fullfile(ivcam2root,'Tools','CalibTools','IV2calibTool','calibParams.xml');
debug_log_f = false;
verbose = true;
save_input_flag = true;
save_output_flag = true;
dummy_output_flag = true;
[calibParams , result] = cal_init(output_dir, calib_dir, calib_params_fn, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag);
%% 
load('\\143.185.124.250\Public\Users\Dror\IVCAM2 CAL\FailMinRangematlab 1.14.0.0\IC2\Matlab\mat_files\Preset_Calib_Calc_in.mat');
InputPath = ('\\143.185.124.250\Public\Users\Dror\IVCAM2 CAL\FailMinRangematlab 1.14.0.0\IC2\Images\MinRange');
[minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc(InputPath,LaserPoints,maxMod_dec,sz,calibParams);


%% DFZ warp
load('\\ger\ec\proj\ha\RSG\SA_3DCam\tzachi\dror\hvm_6_6\AlgoInternalFailure\Matlab\mat_files\DFZ_Calib_Calc_in.mat');
InputPath = '\\ger\ec\proj\ha\RSG\SA_3DCam\tzachi\dror\hvm_6_6\AlgoInternalFailure\Images\DFZ_Algo_With_SR';
[a.dfzRegs,a.results,a.calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs);
%[roiRegs,results,fovData] = ROI_Calib_Calc(InputPath, calibParams, ROIregs,results)


%% end warp
%% cal init function 
output_dir = fullfile(ivcam2tempdir,'unit_test','output_dir');
mkdirSafe(output_dir);
calib_dir = fullfile(ivcam2root,'CompiledAPI','calib_dir');
calib_params_fn =  fullfile(ivcam2root,'Tools','CalibTools','IV2calibTool','calibParams.xml');
debug_log_f = false;
verbose = true;
save_input_flag = true;
save_output_flag = true;
dummy_output_flag = true;
[calibParams , result] = cal_init(output_dir, calib_dir, calib_params_fn, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag);
%% 
load('D:\temp\unitCalib\F9140938\green\PC28\mat_files\END_calib_Calc_in.mat');
fnCalib = 'D:\temp\unitCalib\F9140938\green\PC28\AlgoInternal\calib.csv';
[results ,luts] = END_calib_Calc(delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams,1);




% coverege warp
calibParamsFn = 'D:\tbenshab\algo_203\algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParams.xml';
calibParams = xml2structWrapper(calibParamsFn);
load('D:\temp\unitCalib\F9140938\green\PC28\mat_files\HVM_Val_Coverage_Calc_in.mat');
fnCalib = 'D:\temp\unitCalib\F9140938\green\PC28\AlgoInternal\calib.csv';
mkdirSafe('C:\Users\tbenshab\AppData\Local\Temp\HVM_Val_Coverage_Calc\temp\mat_files');
[valResults ,allResults] = HVM_Val_Coverage_Calc(InputPath,sz,calibParams,valResults);



%% RGB wrap
    %% cal init wrap
    output_dir = fullfile(ivcam2tempdir,'unit_test','output_dir');
    mkdirSafe(output_dir);
    calib_dir = fullfile(ivcam2root,'CompiledAPI','calib_dir');
    calib_params_fn =  fullfile(ivcam2root,'Tools','CalibTools','IV2calibTool','calibParams.xml');
    debug_log_f = false;
    verbose = true;
    save_input_flag = true;
    save_output_flag = true;
    dummy_output_flag = true;
    [calibParams , result] = cal_init(output_dir, calib_dir, calib_params_fn, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag);
    %%
    

%% RGB_Calib_Calc wrap
load('\\143.185.124.250\Public\Users\Dror\IVCAM2 CAL\FailRGBmatlab 1.14.0.0\IC3\Matlab\mat_files\RGB_Calib_Calc_in.mat');
InputPath = ('\\143.185.124.250\Public\Users\Dror\IVCAM2 CAL\FailRGBmatlab 1.14.0.0\IC3\Images\RGBCalibration');
irImSize = [360,640];
[rgbPassed,rgbTable,results] = RGB_Calib_Calc(InputPath,calibParams,irImSize,Kdepth,z2mm);


    %% cal init wrap
    output_dir = fullfile(ivcam2tempdir,'unit_test','output_dir');
    mkdirSafe(output_dir);
    calib_dir = fullfile(ivcam2root,'CompiledAPI','calib_dir');
    calib_params_fn =  fullfile(ivcam2root,'Tools','CalibTools','IV2ThermalCalibTool','calibParams.xml');
    debug_log_f = false;
    verbose = true;
    save_input_flag = true;
    save_output_flag = true;
    dummy_output_flag = true;
    [calibParams , ~] = cal_init(output_dir, calib_dir, calib_params_fn, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag);
    %% thermal calc phase 0
%    load('\\143.185.124.250\Public\Users\Dror\IVCAM2 CAL\FailThermalmatlab 1.15.0.0\IC5\Matlab\mat_files\TemDataFrame_Calc_in0.mat');
   load('\\ger\ec\proj\ha\RSG\SA_3DCam\tzachi\dror\HVM_1928_v4\Failures\IC35\Matlab\mat_files\TemDataFrame_Calc_in0.mat');
%    load('C:\temp\unitCalib\F9240097\TC01\mat_files\TemDataFrame_Calc_in0.mat');
%    InputPath = '\\143.185.124.250\Public\Users\Dror\IVCAM2 CAL\FailThermalmatlab 1.15.0.0\IC5\Images\Thermal\Cycle10';
    InputPath = '\\ger\ec\proj\ha\RSG\SA_3DCam\tzachi\dror\HVM_1928_v3\Failures\IC32\Images\Thermal\Cycle1';
%    [result, tableResults, metrics,invalid_frames]  = TemDataFrame_Calc(regs, FrameData, sz ,InputPath,calibParams, 2);
    [finishedHeating,calibPassed, tableResults, metrics, Invalid_Frames] = TemDataFrame_Calc(regs,eepromRegs,eepromBin,FrameData, sz ,InputPath,calibParams, maxTime2Wait);

    %% algo2 create script
    load('Z:\Dror\IVCAM2 CAL\FailThermalmatlab 1.15.0.1\IC12\Matlab\mat_files\data_out.mat');
    fprintff = @(varargin) fprintf(varargin{:});
    runParams.outputFolder = tempdir;
    [table,tableResults] = Calibration.thermal.generateFWTable(data,calibParams,runParams,fprintff);
    hw = [];
    calibPassed = Calibration.aux.mergeScores(data.results,calibParams.errRange,fprintff);
    Calibration.thermal.generateAndBurnTable(hw,table,calibParams,runParams,fprintff,calibPassed,data,calib_dir);
    
%% full algo2 wrapper
    output_dir = fullfile(ivcam2tempdir,'unit_test','output_dir');
    mkdirSafe(output_dir);
    calib_dir = fullfile(ivcam2root,'CompiledAPI','calib_dir');
    calib_params_fn =  fullfile(ivcam2root,'Tools','CalibTools','IV2ThermalCalibTool','calibParams.xml');
    debug_log_f = false;
    verbose = true;
    save_input_flag = true;
    save_output_flag = true;
    dummy_output_flag = true;
    [calibParams , ~] = cal_init(output_dir, calib_dir, calib_params_fn, debug_log_f ,verbose , save_input_flag , save_output_flag , dummy_output_flag);
    %% thermal calc phase 0
    base_path = '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2235\F9140332\cal2\2nd';
    images_path = fullfile(base_path,'\Images\Thermal');
    matlab_path = fullfile(base_path,'\Matlab\mat_files');
    d = dir(images_path);
    image_list = {d(:).name} ;
    invalidFrames = arrayfun(@(n) strcmp(n,'.')||strcmp(n,'..'),image_list);
    image_list = image_list(~invalidFrames);
    numel(image_list);
    for n = 1:1:numel(image_list)
        mat_fn = fullfile(matlab_path,sprintf('TemDataFrame_Calc_in%d',n-1));
        load(mat_fn);
        InputPath = fullfile(images_path,sprintf('Cycle%d',n));
        [result, tableResults, metrics,invalid_frames]  = TemDataFrame_Calc(regs, FrameData, sz ,InputPath,calibParams, 2);
    end
    %% algo2 create script
    load('Z:\Dror\IVCAM2 CAL\FailThermalmatlab 1.15.0.1\IC12\Matlab\mat_files\data_out.mat');
    fprintff = @(varargin) fprintf(varargin{:});
    runParams.outputFolder = tempdir;
    [table,tableResults] = Calibration.thermal.generateFWTable(data,calibParams,runParams,fprintff);
    hw = [];
    calibPassed = Calibration.aux.mergeScores(data.results,calibParams.errRange,fprintff);
    Calibration.thermal.generateAndBurnTable(hw,table,calibParams,runParams,fprintff,calibPassed,data,calib_dir);
