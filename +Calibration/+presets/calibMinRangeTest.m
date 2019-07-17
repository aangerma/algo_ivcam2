runParams.outputFolder = 'C:\GIT\AlgoProjects\algo_ivcam2\+Calibration\+presets\testingDir';
runParams.testingDir = 'testingDir\AlgoInternal';
calibParams = xml2structWrapper('C:\GIT\AlgoProjects\algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParams.xml');
fprintff = @fprintf;

% Show image request box

% Call the calibration function
hw = HWinterface();
[minRangeScaleModRef,ModRefDec] = Calibration.presets.calibrateMinRange(hw,calibParams,runParams,fprintff);
%%
% Update Presets csv in AlgoInternal fullfile(runParams.outputFolder,'AlgoInternal')

pathSR ="C:\GIT\AlgoProjects\algo_ivcam2\+Calibration\+presets\+defaultValues\shortRangePreset.csv";
shortRangePreset=readtable(pathSR);
modRefix=find(strcmp(shortRangePreset.name,'modulation_ref_factor')); 
% fw=Firmware;
% fw.writeDynamicRangeTable('C:\tmp\New folder\Dynamic_Range_CalibInfo_Ver_1.bin');