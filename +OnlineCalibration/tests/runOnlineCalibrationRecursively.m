clear

% global runParams;
% runParams.loadSingleScene = 1;
% runParams.verbose = 0;
% runParams.saveBins = 0;
% runParams.ignoreSceneInvalidation = 1;
% runParams.ignoreOutputInvalidation = 1;

%%
%rootDir = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\F9440842_scene2';
%rootDir = 'C:\work\autocal\F9440687';
rootDir = 'C:\work\autocal\F9440687\LongRange_D_768x1024_RGB_1920x1080\2';
LRS = false;
scenes = dir([rootDir '\**\*.rsc']);
for i = 1:length(scenes)
    folder = scenes(i).folder;
    runOnlineCalibrationOn( folder, LRS );
end

