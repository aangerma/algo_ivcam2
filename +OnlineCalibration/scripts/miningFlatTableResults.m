clear

uvErrorLimit = 3; % Optimization resulting in a larger uvError is a bad one 



flatTablefn = 'C:\source\algo_ivcam2\+OnlineCalibration\tests\resultsArrayWithKdepthAndRot_22-Mar-2020_table_and_params.mat';
% flatTablefn = 'C:\source\algo_ivcam2\+OnlineCalibration\tests\resultsArrayWithKdepthAndRot_21-Mar-2020_table_and_params.mat';
% flatTablefn = 'C:\source\algo_ivcam2\+OnlineCalibration\tests\resultsArrayWithKdepthAndRotConstantW_23-Mar-2020_table_and_params.mat';
load(flatTablefn);

numberOfScenes = size(resT,1);
numberOfUnreadableScenes = sum(isnan(resT.validScene_isValid)); %Don't have all that is required for optimization, for example - missing rgb images


usefullScenes = ~isnan(resT.uvErrPre); % Scenes with detected CB 
numberOfUsefullScenes = sum(usefullScenes);

fprintff = @fprintf;
fprintff('Analyzing results...\n');
fprintff('Number of scenes %d\n',numberOfScenes);
fprintff('Number of unreadable scenes %d\n',numberOfUnreadableScenes);
fprintff('Number of usefull scenes (CB detected) %d\n',numberOfUsefullScenes);


T = resT(usefullScenes,:);
% For the usefull scenes show:

% 1. Bar plot of uv before and after
figure;
bar([T.uvErrPre,T.uvErrPostPOpt,T.uvErrPostKRTOpt,T.uvErrPostKdepthRTOpt]);
legend({'uvErrPre';'uvErrPostPOpt';'uvErrPostKRTOpt';'uvErrPostKdepthRTOpt'})



%% Show 4 cases:
% 1. We invalidated the scene/output and the uv error was bad
% 2. We invalidated the scene/output and the uv error was good
% 3. We didn't invalidate the scene/output and the uv error was bad
% 4. We didn't invalidate the scene/output and the uv error was good

optTypes = {'uvErrPre';'uvErrPostPOpt';'uvErrPostKRTOpt';'uvErrPostKdepthRTOpt'};

for i = 1:numel(optTypes)
    trueLabels = T.(optTypes{i}) < uvErrorLimit;
    predictedLabels = T.validOutput_isValid & T.validScene_isValid;
    subplot(1,numel(optTypes),i);
    cm = confusionchart(trueLabels,predictedLabels);
    ylabel(sprintf('uvError<%2.2g',uvErrorLimit));
    xlabel('Valid Optimization');
    title(sprintf('confusion Matrix for %s',optTypes{i}));
end