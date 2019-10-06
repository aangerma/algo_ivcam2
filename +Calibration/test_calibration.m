function testsPassed = test_calibration(calibParamsPath,output_dir_Path,DFZ_calib_path,DSM_calib_path,END_calib_path,RGB_calib_path,ROI_calib_path,Short_Preset_calib_path,Long_Preset_state1_calib_path,Long_Preset_state2_calib_path)
% Run validation tests
% testConfig: struct for test defenition:
%  calibParamsPath: (string), path to calibration parameters- algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParamsVXGA.xml
%  output_dir_Path: (string), where test saves what it needs
%  DFZ_calib_path: (string), path to DFZ mat file 
%  DSM_calib_path: (string), path to DSM mat file 
%  END_calib_path: (string), path to END mat file 
%  RGB_calib_path: (string), path to RGB mat file 
%  ROI_calib_path: (string), path to ROI mat file 
%  Short_Preset_calib_path: (string), path to Short Preset mat file 
%  Long_Preset_state1_calib_path: (string), path to Long Preset state1 mat file 
%  Long_Preset_state2_calib_path: (string), path to Long Preset state2 mat file 
%  Debug
% calibParamsPath = 'C:\Users\sbardov\Documents\repfolder\algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParamsVXGA.xml';
% output_dir_Path = 'X:\Avv\sources\calibration\calib_turn_in';
% DFZ_calib_path ='X:\Avv\sources\calibration\PC02\mat_files\DFZ_Calib_Calc_int_in.mat';
% DSM_calib_path = 'X:\Avv\sources\calibration\PC02\mat_files\DSM_Calib_Calc_int_in.mat';
% END_calib_path = 'X:\Avv\sources\calibration\PC02\mat_files\END_calib_Calc_int_in.mat';
% RGB_calib_path = 'X:\Avv\sources\calibration\PC02\mat_files\RGB_calib_Calc_int_in.mat'; 
% ROI_calib_path = 'X:\Avv\sources\calibration\PC02\mat_files\ROI_calib_Calc_int_in.mat'; 
% Short_Preset_calib_path = 'X:\Avv\sources\calibration\PC02\mat_files\Preset_Short_Calib_Calc_int_in.mat'; 
% Long_Preset_state1_calib_path = 'X:\Avv\sources\calibration\PC02\mat_files\Preset_Long_Calib_Calc_state1_int_in.mat'; 
% Long_Preset_state2_calib_path = 'X:\Avv\sources\calibration\PC02\mat_files\Preset_Long_Calib_Calc_state2_int_in.mat';
% test_calibration(calibParamsPath,output_dir_Path,DFZ_calib_path,DSM_calib_path,END_calib_path,RGB_calib_path,ROI_calib_path,Short_Preset_calib_path,Long_Preset_state1_calib_path,Long_Preset_state2_calib_path)

   % output_dir_Path = output_dir_Path{:};	

    ThresholdParams = xml2structWrapper(calibParamsPath);
    fprintff = @fprintf;
    %DFZ calibration
    try
        load(DFZ_calib_path);
        [dfzRegs,calibPassed ,res1] = DFZ_Calib_Calc_int(im, output_dir_Path, ThresholdParams, fprintff, regs);
        dfzPassed = Calibration.aux.mergeScores(res1,ThresholdParams.errRange,fprintff,0); % checks thresholds   
        if dfzPassed
          fprintf('** DFZ calibration test passed \n')
        else
          fprintf('** DFZ calibration test failed \n')
        end
    catch e
        fprintf('** DFZ calibration test failed \n')
        disp(e)
        dfzPassed = 0;
    end
   %DSM calibration

    try
        load(DSM_calib_path);
        [res2, DSM_data,angxZO,angyZO] = DSM_Calib_Calc_int(im, sz , angxRawZOVec , angyRawZOVec ,dsmregs_current ,ThresholdParams,fprintff);
        dsmPassed = (res2 +1)/2; %result =-1\1 --> dsmpassed= 0/1
        if dsmPassed
          fprintf('** DSM calibration test passed \n')
        else
          fprintf('** DSM calibration test failed \n')
        end
    catch e
        fprintf('** DSM calibration test failed \n')
        disp(e)
        dsmPassed=0;
     end
    %END calibration
    try
        load(END_calib_path);
        runParams.outputFolder = output_dir_Path;
        [filepath,~,~] = fileparts(END_calib_path);
        fnCalib = fullfile(filepath,'..','AlgoInternal','calib.csv');
        res3 = End_Calib_Calc_int(runParams,delayRegs, dsmregs,roiRegs,dfzRegs,atlregs,results,fnCalib, fprintff, ThresholdParams);
        endPassed = Calibration.aux.mergeScores(res3,ThresholdParams.errRange,fprintff,0); % checks thresholds     
        if endPassed
          fprintf('** END calibration test passed \n')
        else
          fprintf('** END calibration test failed \n')
        end
    catch e
        fprintf('** END calibration test failed \n')
        disp(e)
        endPassed=0;
    end
    %RGB calibration
    try
        load(RGB_calib_path);
        runParams.outputFolder = output_dir_Path;
        [rgbPassed,rgbTable,res4] = RGB_Calib_Calc_int(im,rgbs,ThresholdParams,Kdepth,fprintff,runParams);
        if rgbPassed
          fprintf('** RGB calibration test passed \n')
        else
           fprintf('** RGB calibration test failed \n')
        end
    catch e
        fprintf('** RGB calibration test failed \n')
        disp(e)
        rgbPassed=0;
    end
    %ROI calibration
    try
        load(ROI_calib_path);
        runParams.outputFolder = output_dir_Path;
        [roiRegs,res5,fovData] = ROI_Calib_Calc_int(im, ThresholdParams, regs,runParams,results);
        roiPassed = Calibration.aux.mergeScores(res5,ThresholdParams.errRange,fprintff,0); % checks thresholds 
        if roiPassed
          fprintf('** ROI calibration test passed \n')
        else
          fprintf('** ROI calibration test failed \n')  
        end
    catch e
        fprintf('** ROI calibration test failed \n')
        disp(e)
        roiPassed=0;
    end
    %Short Preset calibration
    try
        load(Short_Preset_calib_path)
        PresetFolder = fullfile(output_dir_Path,'AlgoInternal');
        [res6.minRangeScaleModRef, res6.maxModRefDec ] = Preset_Short_Calib_Calc_int(im,LaserPoints,maxMod_dec,sz,ThresholdParams,output_dir_Path,PresetFolder);
        spresetPassed = Calibration.aux.mergeScores(res6,ThresholdParams.errRange,fprintff,0); % checks thresholds 
        if spresetPassed
          fprintf('** Short Preset calibration test passed \n')
        else
          fprintf('** Short Preset calibration test failed \n')
        end
    catch e
        fprintf('** Short Preset calibration test failed \n')
        disp(e)
        spresetPassed=0;
    end
    %Long Preset calibration state 1
    try 
        load(Long_Preset_state1_calib_path);
        runParams.outputFolder = output_dir_Path;
        maskParams = ThresholdParams.presets.long.params;
        [res7.maxRangeScaleModRef_state1, res7.maxFillRate_state1, res7.targetDist_state1] = Preset_Long_Calib_Calc_int(maskParams,runParams,ThresholdParams,'state1',im,cameraInput,LaserPoints,maxMod_dec,fprintff);
        lpresetPassed1 = Calibration.aux.mergeScores(res7,ThresholdParams.errRange,@fprintf,0); % checks thresholds
        if lpresetPassed1
          fprintf('** Long Preset calibration test - state 1 passed \n')
        else
          fprintf('** Long Preset calibration test - state 1 failed \n')
        end
    catch e
        fprintf('** Long Preset calibration test - state 1 failed \n')
        disp(e)
        lpresetPassed1=0;
    end
    %Long Preset calibration state 2
    try
        load(Long_Preset_state2_calib_path);
        runParams.outputFolder = output_dir_Path;
        maskParams = ThresholdParams.presets.long.params;
        [res8.maxRangeScaleModRef_state2, res8.maxFillRate_state2, res8.targetDist_state2] = Preset_Long_Calib_Calc_int(maskParams,runParams,ThresholdParams,'state2',im,cameraInput,LaserPoints,maxMod_dec,fprintff);
        lpresetPassed2 = Calibration.aux.mergeScores(res8,ThresholdParams.errRange,@fprintf,0); % checks thresholds 
        if lpresetPassed2
            fprintf('** Long Preset calibration test - state 2 passed \n')
        else
            fprintf('** Long Preset calibration test - state 2 failed \n')
        end
    catch e
        fprintf('** Long Preset calibration test - state 2 failed \n')
        disp(e)
        lpresetPassed2=0;
    end
    %Summary 
    testsPassed = dfzPassed & dsmPassed & endPassed & rgbPassed & roiPassed & spresetPassed & lpresetPassed1 & lpresetPassed2;
    if testsPassed
        fprintf('** All tests passed! \n')
    else
        fprintf('** Some of the tests failed, details above and in log file. \n')
    end
