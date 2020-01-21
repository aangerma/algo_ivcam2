close all
clear all
clc

%% data location

commonPath = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\';
calFolders = {'HENG-2980\FAT Gen05 Step1\After MEMS 8.6.2.0\F9441244\ATC7',...
              'HENG-2943\F9441244\ATC1'};
commonFile = '\Matlab\mat_files\finalCalcAfterHeating_in.mat';
units = cellfun(@(x) (x(strfind(x,'F9')+(0:7))), calFolders, 'UniformOutput', false);

%% display settings

lgnd = {'Gen05', 'ref'};
ttl = units{1};

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
    dataIn.data.ctKillThr           = [0, 65]; % temporary until new SW is released
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
    humGridEdges    = linspace(dataIn.calibParams.fwTable.tempBinRangeRGB(1), dataIn.calibParams.fwTable.tempBinRangeRGB(2), dataIn.calibParams.fwTable.nRowsRGB+2);
    humGrid         = (humGridEdges(1:end-2)+humGridEdges(2:end-1))/2;
    res(iCal).grids = {lddGrid, vBias1Grid, vBias2Grid, vBias3Grid, humGrid};
    res(iCal).table = table;
    res(iCal).rgb   = results.rgb.thermalTable;
    res(iCal).raw   = results.raw;
end
toc

%% display

xlims = [7,73]; % LDD [deg]
errThr = [1.5, 3]+double(nCal>2)*[1.5,1]; % [RMS, max abs]

% RTD
figure
subplot(121)
hold on
for iCal = 1:nCal
    h(iCal) = plot(res(iCal).raw.ldd, res(iCal).raw.rtd, '.');
end
for iCal = 1:nCal
    plot(res(iCal).grids{1}, res(iCal).table(:,5), '-', 'color', get(h(iCal),'color'))
end
grid on, xlabel('LDD [deg]'), ylabel('RTD fix [mm]'), xlim(xlims), legend(lgnd)
subplot(122)
if (nCal==2)
    err = res(1).table(:,5) - res(2).table(:,5);
    ylbl = sprintf('RTD fix difference (%s-%s) [mm]', lgnd{1}, lgnd{2});
else
    err = NaN(size(res(iCal).grids{1}));
    for k = 1:length(err)
        err(k) = diff(minmax(arrayfun(@(x) x.table(k,5), res)));
    end
    ylbl = sprintf('max RTD fix difference (%d calibrations) [mm]', nCal);
end
validIdcs = res(iCal).grids{1}>=xlims(1) & res(iCal).grids{1}<=xlims(2);
res(iCal).grids{1} = res(iCal).grids{1}(validIdcs);
err = err(validIdcs);
if (rms(err)<=errThr(1)) && (max(abs(err))<=errThr(2))
    lgndClr = [0,0.5,0];
else
    lgndClr = [1,0,0];
end
plot(res(iCal).grids{1}, err, '.-')
grid on, xlabel('LDD [deg]'), ylabel(ylbl), xlim(xlims), legend(sprintf('RMS=%.1f, max=%.1f',rms(err),max(abs(err))),'TextColor',lgndClr)
sgtitle(sprintf('%s - depth RTD', ttl))

% LOS
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
        plot(res(iCal).grids{xFitIdcs(iParam)}, res(iCal).table(:,yFitIdcs(iParam)), '-', 'color', get(h(iCal),'color'))
    end
    grid on, xlabel(xLabels{iParam}), ylabel(yLabels{iParam}), legend(lgnd)
end
sgtitle(sprintf('%s - depth LOS', ttl))

% RGB
yLabels = {'scale * cos(angle)', 'scale * sin(angle)', 'X translation [pixels]', 'Y translation [pixels]'};
figure
for iParam = 1:4
    subplot(2,2,iParam)
    hold on
    for iCal = 1:nCal
        plot(res(iCal).grids{5}, res(iCal).rgb(:,iParam), '-', 'color', get(h(iCal),'color'))
    end
    grid on, xlabel('humidity temperature [deg]'), ylabel(yLabels{iParam}), legend(lgnd)
end
sgtitle(sprintf('%s - RGB thermal', ttl))

