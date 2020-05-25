close all
clear all
clc

% groupName = 'PRQ_open';
groupName = 'QNR_1500';
% groupName = 'ACC_repeatability';
% groupName = 'bundle';

%% Data location

switch groupName
    case 'PRQ_open'
        units = {'F0050039';...
                 'F0050045';...
                 'F0050100';...
                 'F0050109'};
        atcGeneralPath{1} = 'X:\Data\IvCam2\Aging\Before';
        accGeneralPath{1} = 'X:\Data\IvCam2\Aging\Before';
        calFolders{1} = {'F0050039\ATC3', 'F0050039\ACC5';...
                         'F0050045\ATC1', 'F0050045\ACC1';...
                         'F0050100\ATC5', 'F0050100\ACC1';...
                         'F0050109\ATC6', 'F0050109\ACC1'};
        atcGeneralPath{2} = 'X:\Data\IvCam2\Aging\After';
        accGeneralPath{2} = 'X:\Data\IvCam2\Aging\After';
        calFolders{2} = {'F0050039\ATC2', 'F0050039\ACC3';...
                         'F0050045\ATC2', 'F0050045\ACC1';...
                         'F0050100\ATC1', 'F0050100\ACC1';...
                         'F0050109\ATC1', 'F0050109\ACC1'};
        isReCalNoBurn = false;
    case 'QNR_1500'
        units = {'F9440703';...
                 'F9440745';...
                 'F9440758';...
                 'F9440831';...
                 'F9440832';...
                 'F9440858';...
                 'F9440870';...
                 'F9440876';...
                 'F9441022';...
                 'F9441108';...
                 'F9441114';...
                 'F9441125';...
                 'F9441126';...
                 'F9441127';...
                 'F9441182';...
                 'F9441196'};
        atcGeneralPath{1} = '';
        accGeneralPath{1} = '';
        calFolders{1} = {};
        atcGeneralPath{2} = 'W:\BIG PBS\HENG-3214\CalNoBurnWOHENG-3158';
        accGeneralPath{2} = 'W:\BIG PBS\HENG-3214\ACCNoBurnWOHENG-3214';
        calFolders{2} = {'F9440703\ATC2', 'F9440703\ACC2';...
                         'F9440745\ATC3', 'F9440745\ACC1';...
                         'F9440758\ATC3', 'F9440758\ACC1';...
                         'F9440831\ATC4', 'F9440831\ACC1';...
                         'F9440832\ATC2', 'F9440832\ACC1';...
                         'F9440858\ATC2', 'F9440858\ACC2';...
                         'F9440870\ATC2', 'F9440870\ACC1';...
                         'F9440876\ATC2', 'F9440876\ACC1';...
                         'F9441022\ATC2', 'F9441022\ACC1';...
                         'F9441108\ATC2', 'F9441108\ACC1';...
                         'F9441114\ATC2', 'F9441114\ACC1';...
                         'F9441125\ATC2', 'F9441125\ACC1';...
                         'F9441126\ATC2', 'F9441126\ACC1';...
                         'F9441127\ATC2', 'F9441127\ACC1';...
                         'F9441182\ATC2', 'F9441182\ACC1';...
                         'F9441196\ATC3', 'F9441196\ACC2'};
        isReCalNoBurn = true;
    case 'ACC_repeatability'
        units = {'F9441174'};
        atcGeneralPath{1} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3205\F9441174';
        accGeneralPath{1} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3253\Cold 10C\F9441174';
        calFolders{1} = {'ATC1', 'ACC4'};
        atcGeneralPath{2} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3205\F9441174';
        accGeneralPath{2} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3253\Cold 10C\F9441174';
        calFolders{2} = {'ATC1', 'ACC5'};
        atcGeneralPath{3} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3205\F9441174';
        accGeneralPath{3} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3253\Cold 10C\F9441174';
        calFolders{3} = {'ATC1', 'ACC6'};
        atcGeneralPath{4} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3205\F9441174';
        accGeneralPath{4} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3253\Hot 50C\F9441174';
        calFolders{4} = {'ATC1', 'ACC7'};
        atcGeneralPath{5} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3205\F9441174';
        accGeneralPath{5} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3253\Hot 50C\F9441174';
        calFolders{5} = {'ATC1', 'ACC8'};
        atcGeneralPath{6} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3205\F9441174';
        accGeneralPath{6} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3253\Hot 50C\F9441174';
        calFolders{6} = {'ATC1', 'ACC9'};
        isReCalNoBurn = true;
    case 'bundle'
        units = {'F0050003';...
                 'F0050016';...
                 'F0050019';...
                 'F0050020';...
                 'F0050023';...
                 'F0050044';...
                 'F0050050';...
                 'F0050051';...
                 'F0050103';...
                 'F0050118';...
                 'F0050119';...
                 'F0050123';...
                 'F0050127';...
                 'F0050130';...
                 'F0050138';...
                 'F0050147';...
                 'F0050150'};
        atcGeneralPath{1} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3203';
        accGeneralPath{1} = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3203';
        calFolders{1} = {'F0050003\ATC1', 'F0050003\ACC1';...
                         'F0050016\ATC1', 'F0050016\ACC1';...
                         'F0050019\ATC1', 'F0050019\ACC1';...
                         'F0050020\ATC1', 'F0050020\ACC1';...
                         'F0050023\ATC1', 'F0050023\ACC1';...
                         'F0050044\ATC1', '';...
                         'F0050050\ATC1', 'F0050050\ACC1';...
                         'F0050051\ATC1', 'F0050051\ACC3';...
                         'F0050103\ATC1', 'F0050103\ACC1';...
                         'F0050118\ATC1', 'F0050118\ACC1';...
                         'F0050119\ATC1', 'F0050119\ACC1';...
                         'F0050123\ATC1', 'F0050123\ACC1';...
                         'F0050127\ATC1', 'F0050127\ACC1';...
                         'F0050130\ATC1', 'F0050130\ACC2';...
                         'F0050138\ATC1', 'F0050138\ACC1';...
                         'F0050147\ATC1', 'F0050147\ACC1';...
                         'F0050150\ATC1', 'F0050150\ACC1'};
end
nUnits = length(units);

%% Validity verification

for iCal = 1:length(calFolders)
    for iUnit = 1:nUnits
        % ATC
        if ~isempty(calFolders{iCal}{iUnit,1})
            atcBinFiles = dir(fullfile(atcGeneralPath{iCal}, calFolders{iCal}{iUnit,1}, 'Matlab\*.bin'));
            if (length(atcBinFiles)<5)
                warning('Incomplete ATC for unit %s', units{iUnit})
            end
        end
        % ACC
        if ~isempty(calFolders{iCal}{iUnit,2})
            accBinFiles = dir(fullfile(accGeneralPath{iCal}, calFolders{iCal}{iUnit,2}, 'Matlab\calibOutputFiles\*.bin'));
            if (length(accBinFiles)<11)
                warning('Incomplete ACC for unit %s', units{iUnit})
            end
        end
    end
end

%% Data extraction

for iCal = 1:length(calFolders)
    for iUnit = 1:nUnits
        if ~isempty(calFolders{iCal}{iUnit,1}) && ~isempty(calFolders{iCal}{iUnit,2})
            fprintf('Fetching calibration data of %s from CAL %d...\n', units{iUnit}, iCal);
            atcPath = fullfile(atcGeneralPath{iCal}, calFolders{iCal}{iUnit,1});
            accPath = fullfile(accGeneralPath{iCal}, calFolders{iCal}{iUnit,2});
            calData(iCal,iUnit) = Calibration.tables.getCalibDataFromCalPath(atcPath, accPath);
        end
    end
end
save(sprintf('cal_data_%s.mat', groupName), 'calData', 'units', 'isReCalNoBurn')
