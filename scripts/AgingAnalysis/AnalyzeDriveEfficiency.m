close all
clear all
clc

%%

unitsPath = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3212\';
calFolders = {'F9440745', 'F9441022\mems1', 'F9441114\mems1', 'F9441196\mems1'};
units = cellfun(@(x) x(1:8), calFolders, 'uni', false);

for iUnit = 1:length(units)
    [unitData(iUnit).driveVals, unitData(iUnit).fovVals, unitData(iUnit).hum] = GetOlValsFromLog(fullfile(unitsPath, calFolders{iUnit}, 'log.txt'));
    [unitData(iUnit).SensOL, unitData(iUnit).SensCL] = getSensitivityFromCalibPID(fullfile(unitsPath, calFolders{iUnit}, 'log.txt'));
end

unitsPath = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3212\RO\';
calFolders = {'F9440745\mems1', 'F9441022\mems1', 'F9441114\mems1', 'F9441196\mems1'};

for iUnit = 1:length(units)
    [unitDataRO(iUnit).driveVals, unitDataRO(iUnit).fovVals, unitDataRO(iUnit).hum] = GetOlValsFromLog(fullfile(unitsPath, calFolders{iUnit}, 'log.txt'));
    [unitDataRO(iUnit).SensOL, unitDataRO(iUnit).SensCL] = getSensitivityFromCalibPID(fullfile(unitsPath, calFolders{iUnit}, 'log.txt'));
end

humDiff = [unitDataRO.hum] - [unitData.hum];
lgnd = arrayfun(@(x) sprintf('%s (%.1f)', units{x}, humDiff(x)), 1:length(units), 'uni', false);

%%

figure
hold on
for iUnit = 1:length(units)
    h(iUnit) = plot(unitData(iUnit).driveVals, unitData(iUnit).fovVals, '.-');
end
for iUnit = 1:length(units)
    plot(unitDataRO(iUnit).driveVals, unitDataRO(iUnit).fovVals, '.--', 'color', get(h(iUnit), 'color'));
end
grid on, xlabel('FA drive'), ylabel('FOV [deg]'), legend(lgnd), title('T0 (solid) vs. RO (dashed)')

%%

figure
hold on
for iUnit = 1:length(units)
    h(iUnit) = plot(unitData(iUnit).fovVals, unitData(iUnit).fovVals./unitData(iUnit).driveVals, '.-');
end
for iUnit = 1:length(units)
    plot(unitDataRO(iUnit).fovVals, unitDataRO(iUnit).fovVals./unitDataRO(iUnit).driveVals, '.--', 'color', get(h(iUnit), 'color'));
end
grid on, xlabel('FOV [deg]'), ylabel('FA drive efficiency [deg/mV]'), legend(lgnd), title('T0 (solid) vs. RO (dashed)')

