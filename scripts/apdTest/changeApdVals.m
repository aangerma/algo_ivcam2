minApd = 8;
maxApd = 18;
apdVal = [minApd:maxApd]';
numVals = numel(apdVal);
imDir = fullfile('X:\Data\APD\longXga',datestr(now,'dd_mmm_YYYY-HH_MM'));

setCmd = 'amcset 4 ';
getCmd = 'amcget 4 0';

hw = HWinterface;
hw.setPresetControlState(1);
hw.startStream;


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
    temp1 = hw.getHumidityTemperature;
    frames(k) = hw.getFrame(30);
    temp2 = hw.getHumidityTemperature;
    temps(k,1) = (temp1+temp2)*0.5;
    disp(['Finished iteration ' num2str(k) '/' num2str(numVals)]);
    disp(['Mean average between consecutive APD values:' num2str(mean(frames(1).z(:)./4-frames(11).z(:)./4)) 'mm']);
end
hw.stopStream;
save([imDir '\data.mat'],'frames','temps','apdVal');