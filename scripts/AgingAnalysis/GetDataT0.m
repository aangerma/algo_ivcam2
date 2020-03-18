close all
clear all
clc

batch = 'open'; % 'bundle' or 'open'

%% Data location

switch batch
    case 'bundle'
        calVersion = 47;
        unitsPath = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3203\';
        calFolders = {'F0050003', 'ATC1', 'ACC1';...
            'F0050016', 'ATC1', 'ACC1';...
            'F0050019', 'ATC1', 'ACC1';...
            'F0050020', 'ATC1', 'ACC1';...
            'F0050023', 'ATC1', 'ACC1';...
            'F0050044', 'ATC1', '';...
            'F0050050', 'ATC1', 'ACC1';...
            'F0050051', 'ATC1', 'ACC3';...
            'F0050103', 'ATC1', 'ACC1';...
            'F0050118', 'ATC1', 'ACC1';...
            'F0050119', 'ATC1', 'ACC1';...
            'F0050123', 'ATC1', 'ACC1';...
            'F0050127', 'ATC1', 'ACC1';...
            'F0050130', 'ATC1', 'ACC2';...
            'F0050138', 'ATC1', 'ACC1';...
            'F0050147', 'ATC1', 'ACC1';...
            'F0050150', 'ATC1', 'ACC1'};
    case 'open'
        calVersion = 41;
        unitsPath = 'X:\Data\IvCam2\Aging\Before\';
        calFolders = {'F0050039', 'ATC3', 'ACC5';...
            'F0050045', 'ATC1', 'ACC1\ACC1';...
            'F0050100', 'ATC5', 'ACC1';...
            'F0050109', 'ATC6', 'ACC1'};
end
units = calFolders(:,1);
nUnits = length(units);

% validity verification
for iUnit = 1:nUnits
    % ATC
    if ~isempty(calFolders{iUnit,2})
        atcBinFiles = dir(fullfile(unitsPath, calFolders{iUnit,1}, calFolders{iUnit,2}, 'Matlab\*.bin'));
        if (length(atcBinFiles)<5)
            warning('Incomplete ATC for unit %s', units{iUnit})
        end
    end
    % ACC
    if ~isempty(calFolders{iUnit,3})
        accBinFiles = dir(fullfile(unitsPath, calFolders{iUnit,1}, calFolders{iUnit,3}, 'Matlab\calibOutputFiles\*.bin'));
        if (length(accBinFiles)<11)
            warning('Incomplete ACC for unit %s', units{iUnit})
        end
    end
end

%%

calibParams = xml2structWrapper('../../Tools/CalibTools/AlgoThermalCalibration/calibParams.xml');
calibParams.tableVersions.mems = 6.01;
for iUnit = 1:nUnits
    if ~isempty(calFolders{iUnit,2}) && ~isempty(calFolders{iUnit,3})
        fprintf('Fetching calibration data from %s...\n', units{iUnit});
        atcPath = fullfile(unitsPath, calFolders{iUnit,1}, calFolders{iUnit,2});
        accPath = fullfile(unitsPath, calFolders{iUnit,1}, calFolders{iUnit,3});
        unitData(iUnit) = GetUnitDataFromCal(atcPath, accPath, calibParams.tableVersions, calVersion);
    end
end
save(sprintf('dataT0_%s.mat', batch), 'unitData', 'units')


