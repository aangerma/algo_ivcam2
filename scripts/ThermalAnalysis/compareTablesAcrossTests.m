close all
clear all
clc

%% data location
commonPath = '\\143.185.124.250\tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2820\';
calFolders = {'F9340026\ATC8',...
              'F9340229\atc',...
              'F9340284\ATC11'};
commonFile = '\Matlab\mat_files\finalCalcAfterHeating_in.mat';

units = cellfun(@(x) (x(2:8)), calFolders, 'UniformOutput', false);
leg = units;
ttl = 'Test';

%% data extraction
tic
nCal = length(calFolders);
for iCal = 1:nCal
    fprintf('Extracting data from %s...\n', calFolders{iCal});
    % data preparation
    dataIn                          = load([commonPath, calFolders{iCal}, commonFile]);
    dataIn.runParams                = struct;
    dataIn.runParams.outputRawData  = true;
    dataIn.fprintff                 = @fprintf;
    dataIn.calibParams              = xml2structWrapper('calibParams.xml');
    % rerun
    invalidFrames           = arrayfun(@(x) isempty(x.ptsWithZ), dataIn.data.framesData');
    dataIn.data.framesData  = dataIn.data.framesData(~invalidFrames);
    dataIn.data.dfzRefTmp   = dataIn.data.regs.FRMW.dfzCalTmp;
    [table, results]        = Calibration.thermal.generateFWTable(dataIn.data, dataIn.calibParams, dataIn.runParams, dataIn.fprintff);
    % reorganization
    lddGrid         = linspace(dataIn.calibParams.fwTable.tempBinRange(1), dataIn.calibParams.fwTable.tempBinRange(2), dataIn.calibParams.fwTable.nRows);
    vBias1Grid      = linspace(results.angx.p0(1), results.angx.p1(1), dataIn.calibParams.fwTable.nRows);
    vBias2Grid      = linspace(results.angy.minval, results.angy.maxval, dataIn.calibParams.fwTable.nRows);
    vBias3Grid      = linspace(results.angx.p0(2), results.angx.p1(2), dataIn.calibParams.fwTable.nRows);
    res(iCal).grids = [lddGrid; vBias1Grid; vBias2Grid; vBias3Grid];
    res(iCal).table = table;
    res(iCal).raw   = results.raw;
    res(iCal).tRef  = results.rtd.refTemp;
end
toc

%% data visualization

figure
hold on
for iCal = 1:nCal
    h(iCal) = plot(res(iCal).raw.ldd, res(iCal).raw.rtd, '.');
end
for iCal = 1:nCal
    plot(res(iCal).grids(1,:), res(iCal).table(:,5), '-', 'color', get(h(iCal),'color'))
end
grid on, xlabel('LDD [deg]'), ylabel('RTD fix [mm]'), xlim([0,75]), legend(leg), title(ttl)

xRawFields = {'vbias1', 'vbias1', 'vbias2', 'vbias2'};
yRawFields = {'dsmXscale', 'dsmXoffset', 'dsmYscale', 'dsmYoffset'};
xFitIdcs = [2, 2, 3, 3];
yFitIdcs = [1, 3, 2, 4];
xLabels = {'vBias1 [V]', 'vBias1 [V]', 'vBias2 [V]', 'vBias2 [V]'};
yLabels = {'X scale [1/deg]', 'X offset [deg]', 'Y scale [1/deg]', 'Y offset [deg]'};

figure
for iParam = 1:4
    subplot(2,2,iParam)
    hold on
    for iCal = 1:nCal
        plot(res(iCal).raw.(xRawFields{iParam}), res(iCal).raw.(yRawFields{iParam}), '.', 'color', get(h(iCal),'color'));
    end
    for iCal = 1:nCal
        plot(res(iCal).grids(xFitIdcs(iParam),:), res(iCal).table(:,yFitIdcs(iParam)), '-', 'color', get(h(iCal),'color'))
    end
    grid on, xlabel(xLabels{iParam}), ylabel(yLabels{iParam}), legend(leg)
end
sgtitle(ttl)


