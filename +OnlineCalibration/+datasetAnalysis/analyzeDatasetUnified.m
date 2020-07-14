clear variables;
close all
% saveExamplesPath = 'X:\IVCAM2_calibration _testing\sceneExamplesAC2';
dbAnalysisFlags.saveExamplesPath = '';
dbAnalysisFlags.shuffleDb = true;
dbAnalysisFlags.sortByRes = true;
dbAnalysisFlags.sortBySerial = true;
dbAnalysisFlags.multiFrameFlow = false;
dbAnalysisFlags.rerunWaitBar = true;
dbAnalysisFlags.rerunWithDSMAug = false;
dbAnalysisFlags.rerunAugPerScene = 20;
dbAnalysisFlags.ignoredSerials = {'f0090290';'f0070118';'f0090356'};
dbAnalysisFlags.dataBase = {'iq'}; %Can be one or more of the following: 'robot', 'iq', 'dataCollection'
assert(~(dbAnalysisFlags.multiFrameFlow && ~dbAnalysisFlags.sortBySerial && ~dbAnalysisFlags.sortByRes));
% dbAnalysisFlags.rerunWithExtrinsicsAug = false;
% Definitions:
resultsHeadDir = 'X:\Data\IvCam2\OnlineCalibration\dbTests';
testSubName = '_AC3_IQ_no_aug_Single';
updateDB = false; %Change to true in case there needs to be an update to the excel data base
rng(1);
%% Update data base excels:
if updateDB
    OnlineCalibration.datasetAnalysis.updateDb(dbAnalysisFlags.dataBase);
end
%% Load all data (except the frames themselves) for test run (if already saved, loads it):
dbData = OnlineCalibration.datasetAnalysis.loadDbInputData(dbAnalysisFlags.dataBase,dbAnalysisFlags);

%% Rerun latest AC Version on data base
if dbAnalysisFlags.multiFrameFlow 
    [resStruct,errStruct] = OnlineCalibration.datasetAnalysis.rerunDbMf(dbData,dbAnalysisFlags);
else
    [resStruct,errStruct] = OnlineCalibration.datasetAnalysis.rerunDb(dbData,dbAnalysisFlags);
end


%% Save Results for further analysis
resultsSubDirName = fullfile(resultsHeadDir,[datestr(now,'yy_mmmm_dd___HH_MM'),testSubName]);
mkdirSafe(resultsSubDirName);
resultsFileName = fullfile(resultsSubDirName,'results.mat');
save(resultsFileName,'resStruct','errStruct','dbAnalysisFlags');


% Analyze results
% OnlineCalibration.datasetAnalysis.analyzeACResults(resStruct,'pathFilterStr',{'f0090356';'f0070118'},'dbAnalysisFlags',dbAnalysisFlags);

