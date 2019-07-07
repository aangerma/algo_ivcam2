% Definitions
distances = 20:10:300; %In cm
savePath = 'X:\Data\gradFilt';
depthControlState = 1;
numOffFrames = 100;
%%
hw = HWinterface();
hw.setPresetControlState(depthControlState);


for k = 1:length(distances)
    %%
%     Default
    hw.cmd('mwd a00e15f0 a00e15f4 00000001 // JFILgrad1bypass');
    hw.cmd('mwd a00e166c a00e1670 00000000 // JFILgrad2bypass');
    hw.shadowUpdate();
    moveRobot2Dist(distances(k));
    saveFrames(hw, distances(k), savePath, 'default');
    %%
    hwCommand = 'mwd a00e1600 a00e1604 00000100 // JFILgrad1thrMaxDiag';
    setOnlyOneGrad1Th(hw, hwCommand);
    saveFrames(hw, distances(k), savePath, 'newConfig');
end
hw.stopStream;

function [status,result] = moveRobot2Dist(dist)
command = ['plink.exe robot@ev3dev algo_ev3/move_by_target.py -t wall_10Reflectivity -d ' num2str(dist) 'cm -a 0'];
[status,result] = system(command);
if contains(result,'Host does not exist')
    [status,result] = system(command);
end
if status ~= 0
    warning([datestr(now, 0) ' ' result]);
    error([datestr(now, 0) ' Command to robot not successful:' num2str(status) ' for distance: ' num2str(dist) '\n']);
end
pause(60);
end

function [] = saveFrames(hw, dist, savePath, name)
    frame = hw.getFrame(10,false); % Reset the buffer
    frame = hw.getFrame(numOffFrames,false);
    str = sprintf([name '_dist_%03d_cm'],dist);
    save(fullfile(savePath,[str '.mat']),'frame');
end