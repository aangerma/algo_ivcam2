function [atcPath,accPath,valid] = serialToCalDirs(serial)
atcPath = '';
accPath = '';
calDir = fullfile('X:\IVCAM2_calibration _testing\unitCalibrationData',serial);
valid = 1;
if exist(calDir, 'dir')
    atcDirs = dir(fullfile(calDir,'ATC*'));
    if isempty(atcDirs) 
        valid = 0;
        return;
    else
        atcPath = fullfile(atcDirs(end).folder,atcDirs(end).name);
    end
    accDirs = dir(fullfile(calDir,'ACC*'));
    if isempty(accDirs) 
        valid = 0;
        return;
    else
        accPath = fullfile(accDirs(end).folder,accDirs(end).name);
    end
else
    valid = 0;
end
end

