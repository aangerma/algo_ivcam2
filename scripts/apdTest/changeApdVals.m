minApd = 8;
maxApd = 18;
apdVal = [minApd:maxApd]';
numVals = numel(apdVal);
preset = 'short';
switch preset
case 'long'
        baseFolder = 'X:\Data\APD\longXga';
        presetNum = 1;
    case 'short'
        baseFolder = 'X:\Data\APD\shortXga';
        presetNum = 2;
    otherwise
        error('No Such Preset')
end
imDir = fullfile(baseFolder,datestr(now,'dd_mmm_YYYY-HH_MM'));

setCmd = 'amcset 4 ';
getCmd = 'amcget 4 0';

hw = HWinterface;
hw.cmd('DIRTYBITBYPASS');
hw.setPresetControlState(presetNum);
hw.startStream;
hw.setReg('DESTdepthAsRange',1);
hw.setReg('DESTbaseline$',single(0));
hw.setReg('DESTbaseline2',single(0)); 
hw.shadowUpdate;
pause(10);


mkdirSafe(imDir);
temps = nan(numVals,1);
for k = 1:numVals
    hw.cmd([setCmd dec2hex(apdVal(k))]);
    pause(10);
    s = hw.cmd(getCmd);
    s = strsplit(s,'> ');
    valFromUnit = hex2dec((s{end}(1:2)));
    if valFromUnit ~= apdVal(k)
        error('Value was not updated');
    end
%     temp1 = hw.getHumidityTemperature;
    temp1 = getApdTemp(hw);
    frames(k) = hw.getFrame(30);
%     temp2 = hw.getHumidityTemperature;
    temp2 = getApdTemp(hw);
    temps(k,1) = (temp1+temp2)*0.5;
    disp(['Finished iteration ' num2str(k) '/' num2str(numVals)]);
    if k >1
        disp(['Mean average RTD diff between consecutive APD values:' num2str(mean(frames(k-1).z(:)./2-frames(k).z(:)./2)) 'mm']);
    end
end
% hw.stopStream;
save([imDir '\data.mat'],'frames','temps','apdVal');

function [apdTemp] = getApdTemp(hw)
s = hw.cmd('TEMPERATURES_GET');
s = strsplit(s,'APD_Temperature: ');
s = strsplit(s{end},'HUM_Temperature: ');
apdTemp = str2double(s{1});
end