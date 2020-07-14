clear

%%
%rootDir = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\F9440842_scene2';
rootDir = 'C:\work\autocal\scenes\New\B52\iteration11\ac_11\1';
%rootDir = 'C:\work\autocal\scenes\B30\iteration12\ac_12\1';
%rootDir = 'C:\work\librealsense\build\unit-tests\algo\depth-to-rgb-calibration\19.2.20\F9440687\LongRange_D_768x1024_RGB_1920x1080\';
%rootDir = 'C:\work\autocal\F9440687\LongRange_D_768x1024_RGB_1920x1080\2';
LRS = false;
scenes = dir([rootDir '\**\*.rsc']);
for i = 1:length(scenes)
    folder = scenes(i).folder;
    try
        runOnlineCalibration( folder, 'ac1' );
    catch ME
        warning( ME.message )
        dumpstack( ME.stack )
    end
end
scenes = dir([rootDir '\**\InputData.mat']);
for i = 1:length(scenes)
    folder = scenes(i).folder;
    try
        runOnlineCalibration( folder, 'iqData' );
    catch ME
        warning( ME.message )
        dumpstack( ME.stack )
    end
end
scenes = dir([rootDir '\**\camera_params']);
for i = 1:length(scenes)
    folder = scenes(i).folder;
    try
        runOnlineCalibration( folder, 'lrs' );
    catch ME
        warning( ME.message )
        dumpstack( ME.stack )
    end
end
function dumpstack(S)

for i = 1:length(S)
    disp([ '>    ' S(i).name ' (line ' num2str(S(i).line) ')' ])
end

end
