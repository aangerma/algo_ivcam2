close all
clear all
clc

groupName = 'PRQ_open';
% groupName = 'ACC_repeatability';
% groupName = 'bundle';

calsToCompare = [1,2];

plotFlags.algoThermal = true;
plotFlags.miscThermal = true;
plotFlags.los = true;
plotFlags.rgb = true;

%% Data loading

nCal = length(calsToCompare);
assert(nCal==2, 'Only 2 calibrations can be compared each time')
load(sprintf('cal_data_%s.mat', groupName), 'calData', 'units')
calData = calData(calsToCompare,:);
nUnits = length(units);

%% Default configurations

lddGrid = 0:2:94;
nThermalBins = length(lddGrid);
lddLims = [5, 75];

figPos1x1 = [680, 224, 515, 377];
figPos1x2 = [680, 224, 1030, 377];
figPos1x2small = [680, 224, 722, 282];
figPos2x2 = [680, 224, 1030, 754];
figPos2x3 = [230, 224, 1645, 754];

plotColors = [0.0000  0.4470  0.7410;...
              0.8500  0.3250  0.0980;...
              0.9290  0.6940  0.1250;...
              0.4940  0.1840  0.5560;...
              0.4660  0.6740  0.1880;...
              0.3010  0.7450  0.9330;...
              0.6350  0.0780  0.1840];

%% Algo thermal tables

if plotFlags.algoThermal
    
    % system delay - preparations
    getSysDelayChange = @(x,tableName,withNomDelay) (withNomDelay*x(2).regs.DEST.txFRQpd(1)-x(2).tables.(tableName)(:,end)) - (withNomDelay*x(1).regs.DEST.txFRQpd(1)-x(1).tables.(tableName)(:,end));
    sysDelayTypes = {'relative to ref. temp.', 'absolute'};
    % system delay - plotting
    figure('Name', 'ThermalRtd', 'Position', figPos2x2)
    for iType = 1:2
        subplot(2,2,iType), hold on
        for iUnit = 1:nUnits
            plot(lddGrid, getSysDelayChange(calData(:,iUnit), 'thermal', iType-1), '.-')
        end
        grid on, xlim(lddLims), xlabel('LDD [\circC]'), ylabel('change [mm]'), legend(units), title(sprintf('Long preset (%s)', sysDelayTypes{iType}))
        subplot(2,2,2+iType), hold on
        for iUnit = 1:nUnits
            plot(lddGrid, getSysDelayChange(calData(:,iUnit), 'thermalShort', iType-1), '.-')
        end
        grid on, xlim(lddLims), xlabel('LDD [\circC]'), ylabel('change [mm]'), legend(units), title(sprintf('Short preset (%s)', sysDelayTypes{iType}))
    end
    sgtitle('Thermal system delay')
    
    % DSM table - preparations
    tableIdcs = [1,3,2,4];
    params = {'X scale', 'X offset', 'Y scale', 'Y offset'};
    getVBias = @(x,iPzr) linspace(x.regs.FRMW.(sprintf('atlMinVbias%d',iPzr)), x.regs.FRMW.(sprintf('atlMaxVbias%d',iPzr)), nThermalBins);
    xlbls = {'vBias1 [V]', 'vBias1 [V]', 'vBias2 [V]', 'vBias2 [V]'};
    ylbls = {'scale [1/\circ]', 'offset [\circ]', 'scale [1/\circ]', 'offset [\circ]'};
    plotStyles = {'.-', '.--'};
    % DSM table - plotting
    figure('Name', 'ThermalDsm', 'Position', figPos2x2)
    for iParam = 1:4
        subplot(2,2,iParam), hold on
        for iCal = 1:nCal
            for iUnit = 1:nUnits
                plot(getVBias(calData(iCal,iUnit), 1+mod(iParam-1,2)), calData(iCal,iUnit).tables.thermal(:,tableIdcs(iParam)), plotStyles{iCal}, 'color', plotColors(iUnit,:))
            end
        end
        grid on, xlabel(xlbls{iParam}), ylabel(ylbls{iParam}), legend(units), title(params{iParam})
    end
    sgtitle('Thermal DSM (solid - 1st CAL, dashed - 2nd CAL)')
    
    % DSM operation - preparations
    nPts = 101;
    xLosVec = linspace(-31.05, 31.05, nPts); % 72deg after FOVex
    yLosVec = linspace(-24.33, 24.33, nPts); % 55deg after FOVex
    vBiasMat = zeros(3, nThermalBins, nUnits);
    xDsmChange = zeros(nThermalBins, nPts, nUnits);
    yDsmChange = zeros(nThermalBins, nPts, nUnits);
    for iUnit = 1:nUnits
        vBiasMat(:,:,iUnit) = [getVBias(calData(1,iUnit),1); getVBias(calData(1,iUnit),2); getVBias(calData(1,iUnit),3)];
        xDsmMat1 = (xLosVec + double(calData(1,iUnit).tables.thermal(:,3))) .* double(calData(1,iUnit).tables.thermal(:,1)) - 2047;
        yDsmMat1 = (yLosVec + double(calData(1,iUnit).tables.thermal(:,4))) .* double(calData(1,iUnit).tables.thermal(:,2)) - 2047;
        dsmVals = Calibration.tables.calc.calcAlgoThermalDsmRtd(struct('table', calData(2,iUnit).tables.thermal), calData(2,iUnit).regs, lddGrid([1,end]), lddGrid, vBiasMat(:,:,iUnit));
        xDsmMat2 = (xLosVec + double(dsmVals.xOffset)) .* double(dsmVals.xScale) - 2047;
        yDsmMat2 = (yLosVec + double(dsmVals.yOffset)) .* double(dsmVals.yScale) - 2047;
        xDsmChange(:,:,iUnit) = xDsmMat2-xDsmMat1;
        yDsmChange(:,:,iUnit) = yDsmMat2-yDsmMat1;
    end
    plotIdcs = (lddGrid>=lddLims(1) & lddGrid<=lddLims(2));
    % DSM operation - plotting
    for iUnit = 1:nUnits
        figure('Name', 'DsmMapping', 'Position', figPos1x2small)
        subplot(121), hold on
        contourf(xLosVec, vBiasMat(1,plotIdcs,iUnit), abs(xDsmChange(plotIdcs,:,iUnit)))
        grid on, xlabel('LOS x [\circ]'), ylabel('vBias1 [V]'), title('angx absolute change'), colorbar
        subplot(122), hold on
        contourf(yLosVec, vBiasMat(2,plotIdcs,iUnit), abs(yDsmChange(plotIdcs,:,iUnit)))
        grid on, xlabel('LOS y [\circ]'), ylabel('vBias2 [V]'), title('angy absolute change'), colorbar
        sgtitle(sprintf('DSM mapping for %s [DSM units] (LDD %d\\circC-%d\\circC)', units{iUnit}, lddLims(1), lddLims(2)))
    end
    
end

%% Miscellaneous thermal parameters

if plotFlags.miscThermal
    
    % vBias - preparations
    vBiasChange = cell(1,nUnits);
    for iUnit = 1:nUnits
        hum = calData(1,iUnit).heating.hum;
        nMeas = length(hum);
        hum = hum+(1:nMeas)/nMeas*1e-3; % trick for guaranteeing unique points (finer than SHTW2 measurement resolution of 0.0026705)
        vBiasChange{iUnit} = zeros(3, length(calData(2,iUnit).heating.hum));
        for iPzr = 1:3
            vBias1AtHum2 = interp1(hum, calData(1,iUnit).heating.vBias(iPzr,:), calData(2,iUnit).heating.hum, 'pchip');
            vBiasChange{iUnit}(iPzr,:) = calData(2,iUnit).heating.vBias(iPzr,:)-vBias1AtHum2;
        end
    end
    plotStyles = {'-', '--'};
    % vBias - plotting
    figure('Name', 'vBias', 'Position', figPos2x3)
    for iPzr = 1:3
        subplot(2,3,iPzr), hold on
        for iCal = 1:nCal
            for iUnit = 1:nUnits
                plot(calData(iCal,iUnit).heating.hum, calData(iCal,iUnit).heating.vBias(iPzr,:), plotStyles{iCal}, 'color', plotColors(iUnit,:))
            end
        end
        grid on, xlabel('humidity temperature [\circ]'), ylabel(sprintf('vBias%d [V]',iPzr)), legend(units)
        subplot(2,3,3+iPzr), hold on
        for iUnit = 1:nUnits
            plot(calData(2,iUnit).heating.hum, vBiasChange{iUnit}(iPzr,:), '.', 'color', plotColors(iUnit,:))
        end
        for iUnit = 1:nUnits
            smoothedChange = smooth(vBiasChange{iUnit}(iPzr,:), 50)';
            plot(calData(2,iUnit).heating.hum(13:end-12), smoothedChange(13:end-12), '-', 'linewidth', 2, 'color', plotColors(iUnit,:))
        end
        grid on, xlabel('humidity temperature [\circ]'), ylabel(sprintf('vBias%d change [V]',iPzr)), legend(units)
        sgtitle('Thermal vBias (solid - 1st CAL, dashed - 2nd CAL)')
    end
    
    % Projection drift - preparations
    getProjUnion = @(x) cat(1, double([x.regs.FRMW.atlMinAngXL, x.regs.FRMW.atlMaxAngXR]) * [1,1,0,0,1; 0,0,1,1,0], double([x.regs.FRMW.atlMinAngYU, x.regs.FRMW.atlMaxAngYB]) * [1,0,0,1,1; 0,1,1,0,0]);
    getProjIntersect = @(x) cat(1, double([x.regs.FRMW.atlMaxAngXL, x.regs.FRMW.atlMinAngXR]) * [1,1,0,0,1; 0,0,1,1,0], double([x.regs.FRMW.atlMaxAngYU, x.regs.FRMW.atlMinAngYB]) * [1,0,0,1,1; 0,1,1,0,0]);
    getProjLRUB = @(x) [x.regs.FRMW.atlMaxAngXL; x.regs.FRMW.atlMinAngXR; x.regs.FRMW.atlMaxAngYU; x.regs.FRMW.atlMinAngYB];
    projUnion = zeros(2, 5, nUnits, nCal);
    projIntersect = zeros(2, 5, nUnits, nCal);
    projLRUB = zeros(4, nUnits, nCal);
    for iCal = 1:nCal
        for iUnit = 1:nUnits
            projUnion(:,:,iUnit,iCal) = getProjUnion(calData(iCal,iUnit));
            projIntersect(:,:,iUnit,iCal) = getProjIntersect(calData(iCal,iUnit));
            projLRUB(:,iUnit,iCal) = getProjLRUB(calData(iCal,iUnit));
        end
    end
    % Projection drift - plotting
    if false
        for iUnit = 1:nUnits
            figure('Name', 'Projection', 'Position', figPos1x1), hold on
            plot(projUnion(1,:,iUnit,1), projUnion(2,:,iUnit,1), 'k-')
            plot(projIntersect(1,:,iUnit,1), projIntersect(2,:,iUnit,1), 'r-')
            plot(projUnion(1,:,iUnit,2), projUnion(2,:,iUnit,2), 'k--')
            plot(projIntersect(1,:,iUnit,2), projIntersect(2,:,iUnit,2), 'r--')
            grid on, xlabel('angx [DSM units]'), ylabel('angy [DSM units]'), legend('union', 'intersection'), title(sprintf('%s (solid - 1st CAL, dashed - 2nd CAL', units{iUnit}))
        end
    end
    figure('Name', 'ProjectionLims', 'Position', figPos1x1), hold on
    for iUnit = 1:nUnits
        plot(squeeze(diff(projLRUB(:,iUnit,:),[],3)), '-o')
    end
    grid on, set(gca, 'XTick', 1:nUnits), set(gca, 'XTickLabel', {'left', 'right', 'top' ,'bottom'}), ylabel('change [DSM units]'), legend(units), title('Change in projection thermal intersection')
    
    % Sync loop - preparations
    zSlope = zeros(nUnits, nCal);
    zOffset = zeros(nUnits, nCal);
    irSlope = zeros(nUnits, nCal);
    irOffset = zeros(nUnits, nCal);
    for iUnit = 1:nUnits
        for iCal = 1:nCal
            zDelay = calData(iCal,iUnit).regs.EXTL.conLocDelayFastC+calData(iCal,iUnit).regs.EXTL.conLocDelayFastF;
            irDelay = uint32(int32(zDelay)-int32(mod(calData(iCal,iUnit).regs.EXTL.conLocDelaySlow,2^31)));
            zSlope(iUnit,iCal) = calData(iCal,iUnit).regs.FRMW.conLocDelayFastSlope;
            zOffset(iUnit,iCal) = single(zDelay) - zSlope(iUnit,iCal)*calData(iCal,iUnit).regs.FRMW.dfzCalTmp;
            irSlope(iUnit,iCal) = calData(iCal,iUnit).regs.FRMW.conLocDelaySlowSlope;
            irOffset(iUnit,iCal) = single(irDelay) - irSlope(iUnit,iCal)*calData(iCal,iUnit).regs.FRMW.dfzCalTmp;
        end
    end
    
    % Sync loop - plotting
    figure('Name', 'SyncLoop', 'Position', figPos1x2)
    subplot(121), hold on
    for iUnit = 1:nUnits
        plot(lddLims, diff(irSlope(iUnit,:))*lddLims+diff(irOffset(iUnit,:)), '.-');
    end
    grid on, xlabel('LDD [\circ]'), ylabel('IR delay change [nsec]'), legend(units)
    subplot(122), hold on
    for iUnit = 1:nUnits
        plot(lddLims, diff(zSlope(iUnit,:))*lddLims+diff(zOffset(iUnit,:)), '.-');
    end
    grid on, xlabel('LDD [\circ]'), ylabel('Z delay change [nsec]'), legend(units)
    sgtitle('Sync loop change')
    
end

%% LOS errors

if plotFlags.los
    
    % Mirror rest - preparations
    defaultScaleX = 61.62;
    defaultOffsetX = 33.99;
    defaultScaleY = 68.77;
    defaultOffsetY = 31.14;
    horzLosAtRest = arrayfun(@(x) (x.regs.FRMW.losAtMirrorRestHorz+2047)/defaultScaleX - defaultOffsetX, calData);
    vertLosAtRest = arrayfun(@(y) (y.regs.FRMW.losAtMirrorRestVert+2047)/defaultScaleY - defaultOffsetY, calData);
    plotStyles = {'-o', '--s'};
    % Mirror rest - plotting
    figure('Name', 'MirrorRest', 'Position', figPos1x2)
    subplot(121), hold on
    for iCal = 1:nCal
        plot(1:nUnits, horzLosAtRest(iCal,:), plotStyles{iCal});
    end
    grid on, set(gca, 'XTick', 1:nUnits), set(gca, 'XTickLabel', units), ylabel('horizontal LOS [\circ]')
    subplot(122), hold on
    for iCal = 1:nCal
        plot(1:nUnits, vertLosAtRest(iCal,:), plotStyles{iCal});
    end
    grid on, set(gca, 'XTick', 1:nUnits), set(gca, 'XTickLabel', units), ylabel('vertical LOS [\circ]')
    sgtitle('LOS at mirror rest (solid - 1st CAL, dashed - 2nd CAL')
    
    % LOS change - preparations
    nPts = 101;
    midLosInd = ceil(nPts/2);
    xLosVec = linspace(-31.05, 31.05, nPts); % 72deg after FOVex
    yLosVec = linspace(-24.74, 24.74, nPts); % 56deg after FOVex
    xLos = repmat(xLosVec, [nPts,1]);
    yLos = repmat(yLosVec', [1,nPts]);
    fovBoundaries = [70, 55]; % ignore results beyond this FOV in image plane
    plotIdcs = find(lddGrid>=lddLims(1) & lddGrid<=lddLims(2));
    midThermalInd = plotIdcs(ceil(length(plotIdcs)/2));
    plotVsLdd = true; % otherwise - plot vs. vBias
    thermalForX = repmat(lddGrid, nUnits, 1);
    thermalForY = repmat(lddGrid, nUnits, 1);
    if plotVsLdd
        thermalLabelForX = {'LDD', ' [\circC]'};
        thermalLabelForY = {'LDD', ' [\circC]'};
    else
        thermalLabelForX = {'vBias1', ' [V]'};
        thermalLabelForY = {'vBias2', ' [V]'};
    end
    xLosChange = zeros(nPts, nPts, nThermalBins, nUnits);
    yLosChange = zeros(nPts, nPts, nThermalBins, nUnits);
    applyCorrection = true;
    if applyCorrection
        losChangeCoef = struct('xScale', zeros(nUnits, nThermalBins), 'xOffset', zeros(nUnits, nThermalBins), 'yScale', zeros(nUnits, nThermalBins), 'yOffset', zeros(nUnits, nThermalBins));
    end
    for iUnit = 1:nUnits
        fprintf('Processing %s... ', units{iUnit});
        t0 = tic;
        atlRegs = calData(1,iUnit).regs.FRMW; % vBias sampled as in table of 1st calibration
        vBiasMat = [linspace(atlRegs.atlMinVbias1, atlRegs.atlMaxVbias1, nThermalBins); linspace(atlRegs.atlMinVbias2, atlRegs.atlMaxVbias2, nThermalBins); linspace(atlRegs.atlMinVbias3, atlRegs.atlMaxVbias3, nThermalBins)];
        if ~plotVsLdd
            thermalForX(iUnit,:) = vBiasMat(1,:);
            thermalForY(iUnit,:) = vBiasMat(2,:);
        end
        for iThermal = plotIdcs
            if plotVsLdd
                [xLosTrue1, yLosTrue1] = CalcTrueLos(calData(1,iUnit).regs, calData(1,iUnit).tables.thermal, calData(1,iUnit).tpsUndistModel, xLos, yLos, lddGrid(iThermal));
                [xLosTrue2, yLosTrue2, xOutbound, yOutbound] = CalcTrueLos(calData(2,iUnit).regs, calData(2,iUnit).tables.thermal, calData(2,iUnit).tpsUndistModel, xLos, yLos, lddGrid(iThermal));
            else
                [xLosTrue1, yLosTrue1] = CalcTrueLos(calData(1,iUnit).regs, calData(1,iUnit).tables.thermal, calData(1,iUnit).tpsUndistModel, xLos, yLos, lddGrid(iThermal), vBiasMat(:,iThermal));
                [xLosTrue2, yLosTrue2, xOutbound, yOutbound] = CalcTrueLos(calData(2,iUnit).regs, calData(2,iUnit).tables.thermal, calData(2,iUnit).tpsUndistModel, xLos, yLos, lddGrid(iThermal), vBiasMat(:,iThermal));
            end
            outOfFovIdcs = (abs(tand(xOutbound))>tand(fovBoundaries(1)/2)) | (abs(tand(yOutbound)./cosd(xOutbound))>tand(fovBoundaries(2)/2));
            xLosTrue1(outOfFovIdcs) = NaN;
            yLosTrue1(outOfFovIdcs) = NaN;
            xLosNew = reshape(griddata(vec(double(xLosTrue2)), vec(double(yLosTrue2)), vec(xLos), vec(double(xLosTrue1)), vec(double(yLosTrue1))), nPts, nPts);
            yLosNew = reshape(griddata(vec(double(xLosTrue2)), vec(double(yLosTrue2)), vec(yLos), vec(double(xLosTrue1)), vec(double(yLosTrue1))), nPts, nPts);
            if applyCorrection
                validIdcs = ~isnan(xLosNew);
                p = polyfit(xLos(validIdcs), xLosNew(validIdcs), 1);
                losChangeCoef.xScale(iUnit, iThermal) = p(1);
                losChangeCoef.xOffset(iUnit, iThermal) = p(2)/p(1);
                xLosNew = (xLosNew-p(2))/p(1);
                p = polyfit(yLos(validIdcs), yLosNew(validIdcs), 1);
                losChangeCoef.yScale(iUnit, iThermal) = p(1);
                losChangeCoef.yOffset(iUnit, iThermal) = p(2)/p(1);
                yLosNew = (yLosNew-p(2))/p(1);
            end
            xLosChange(:, :, iThermal, iUnit) = xLosNew-xLos;
            yLosChange(:, :, iThermal, iUnit) = yLosNew-yLos;
        end
        fprintf('Done (%.1f sec)\n', toc(t0));
    end
    % LOS change - plotting
    for iUnit = 1:nUnits
        figure('Name', 'LosChangeThermal', 'Position', figPos1x1)
        subplot(121), hold on
        xLims = [find(xLosVec<-25, 1, 'last'), find(xLosVec>25, 1, 'first')];
        plot(thermalForX(iUnit,plotIdcs), squeeze(xLosChange(midLosInd,xLims(1),plotIdcs,iUnit)))
        plot(thermalForX(iUnit,plotIdcs), squeeze(xLosChange(midLosInd,midLosInd,plotIdcs,iUnit)))
        plot(thermalForX(iUnit,plotIdcs), squeeze(xLosChange(midLosInd,xLims(2),plotIdcs,iUnit)))
        grid on, xlabel([thermalLabelForX{1},thermalLabelForX{2}]), ylabel('change [\circ]'), legend(sprintf('x=%.1f[deg]',xLosVec(xLims(1))), sprintf('x=%.1f[deg]',xLosVec(midLosInd)), sprintf('x=%.1f[deg]',xLosVec(xLims(2)))), title(sprintf('X change for y=%.1f[deg]', yLosVec(midLosInd)))
        subplot(122), hold on
        yLims = [find(yLosVec<-20, 1, 'last'), find(yLosVec>20, 1, 'first')];
        plot(thermalForY(iUnit,plotIdcs), squeeze(yLosChange(yLims(1),midLosInd,plotIdcs,iUnit)))
        plot(thermalForY(iUnit,plotIdcs), squeeze(yLosChange(midLosInd,midLosInd,plotIdcs,iUnit)))
        plot(thermalForY(iUnit,plotIdcs), squeeze(yLosChange(yLims(2),midLosInd,plotIdcs,iUnit)))
        grid on, xlabel([thermalLabelForY{1},thermalLabelForY{2}]), ylabel('change [\circ]'), legend(sprintf('y=%.1f[deg]',yLosVec(yLims(1))), sprintf('y=%.1f[deg]',yLosVec(midLosInd)), sprintf('y=%.1f[deg]',yLosVec(yLims(2)))), title(sprintf('Y change for x=%.1f[deg]', xLosVec(midLosInd)))
        sgtitle(sprintf('LOS change for unit %s', units{iUnit}))
        
        figure('Name', 'LosChangeSection', 'Position', figPos1x1)
        subplot(121), hold on
        yLims = [find(yLosVec<-20, 1, 'last'), find(yLosVec>20, 1, 'first')];
        plot(xLosVec, squeeze(xLosChange(yLims(1),:,midThermalInd,iUnit)))
        plot(xLosVec, squeeze(xLosChange(midLosInd,:,midThermalInd,iUnit)))
        plot(xLosVec, squeeze(xLosChange(yLims(2),:,midThermalInd,iUnit)))
        grid on, xlabel('x [deg]'), ylabel('change [deg]'), legend(sprintf('y=%.1f[deg]',yLosVec(yLims(1))), sprintf('y=%.1f[deg]',yLosVec(midLosInd)), sprintf('y=%.1f[deg]',yLosVec(yLims(2)))), title(sprintf('X change for %s = %.1f%s', thermalLabelForX{1}, thermalForY(iUnit,midThermalInd), thermalLabelForX{2}))
        subplot(122), hold on
        xLims = [find(xLosVec<-25, 1, 'last'), find(xLosVec>25, 1, 'first')];
        plot(yLosVec, squeeze(yLosChange(:,xLims(1),midThermalInd,iUnit)))
        plot(yLosVec, squeeze(yLosChange(:,midLosInd,midThermalInd,iUnit)))
        plot(yLosVec, squeeze(yLosChange(:,xLims(2),midThermalInd,iUnit)))
        grid on, xlabel('y [deg]'), ylabel('change [deg]'), legend(sprintf('x=%.1f[deg]',xLosVec(xLims(1))), sprintf('x=%.1f[deg]',xLosVec(midLosInd)), sprintf('x=%.1f[deg]',xLosVec(xLims(2)))), title(sprintf('Y change for %s = %.1f%s', thermalLabelForY{1}, thermalForY(iUnit,midThermalInd), thermalLabelForY{2}))
        sgtitle(sprintf('LOS aging for unit %s', units{iUnit}))
        
        figure('Name', 'LosChangeMap', 'Position', figPos1x1), hold on
        err = sqrt(xLosChange(:,:,midThermalInd,iUnit).^2+yLosChange(:,:,midThermalInd,iUnit).^2);
        contourf(xLosVec, yLosVec, err);
        set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
        grid on, axis equal, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('LOS aging for %s @ %s = %.1f%s', units{iUnit}, thermalLabelForY{1}, thermalForY(iUnit,midThermalInd), thermalLabelForY{2}))
        
        if applyCorrection
            figure('Name', 'LosCorrect', 'Position', figPos1x1)
            subplot(121), hold on
            plot(thermalForX(iUnit,plotIdcs), losChangeCoef.xScale(iUnit,plotIdcs))
            plot(thermalForY(iUnit,plotIdcs), losChangeCoef.yScale(iUnit,plotIdcs))
            grid on, xlabel([thermalLabelForY{1},thermalLabelForY{2}]), ylabel('change scale [1/deg]'), legend('x', 'y')
            subplot(122), hold on
            plot(thermalForX(iUnit,plotIdcs), losChangeCoef.xOffset(iUnit,plotIdcs))
            plot(thermalForY(iUnit,plotIdcs), losChangeCoef.yOffset(iUnit,plotIdcs))
            grid on, xlabel([thermalLabelForY{1},thermalLabelForY{2}]), ylabel('change offset [deg]'), legend('x', 'y')
            sgtitle(sprintf('Optimal lineat fit for LOS change for %s', units{iUnit}))
        end
    end
    
end

%%

if plotFlags.rgb
    
    % RGB thermal - preparations
    humGrid = 1.25:2.5:72.5;
    nHumBins = length(humGrid);
    rgbThermalScale = zeros(nHumBins, nCal, nUnits);
    rgbThermalRotAng = zeros(nHumBins, nCal, nUnits);
    rgbThermalTrans = zeros(nHumBins, 2, nCal, nUnits);
    rgbCalTmpDiff = diff(arrayfun(@(x) x.rgb.humCal, calData), [], 1);
    for iCal = 1:nCal
        for iUnit = 1:nUnits
            rgbThermalTable = calData(iCal,iUnit).tables.rgbThermal;
            if (iCal==1) % adjust table to difference between calibration temperatures
                rgbThermalTable = interp1(humGrid, rgbThermalTable, max(humGrid(1), min(humGrid(end), humGrid-rgbCalTmpDiff(iUnit))));
            end
            rgbThermalScale(:,iCal,iUnit) = sqrt(sum(rgbThermalTable(:,1:2).^2,2));
            rgbThermalRotAng(:,iCal,iUnit) = atand(rgbThermalTable(:,2)./rgbThermalTable(:,1));
            rgbThermalTrans(:,:,iCal,iUnit) = rgbThermalTable(:,3:4);
        end
    end
    plotStyles = {'-', '--'};
    transLabels = {'horizontal', 'vertical'};
    % RGB thermal - plotting
    figure('Name', 'RgbThermal', 'Position', figPos2x2)
    subplot(221), hold on
    for iCal = 1:nCal
        for iUnit = 1:nUnits
            plot(humGrid, rgbThermalScale(:,iCal,iUnit), plotStyles{iCal}, 'color', plotColors(iUnit,:))
        end
    end
    grid on, xlabel('humidity temperature [\circC]'), ylabel('scaling factor'), legend(units)
    subplot(222), hold on
    for iCal = 1:nCal
        for iUnit = 1:nUnits
            plot(humGrid, rgbThermalRotAng(:,iCal,iUnit), plotStyles{iCal}, 'color', plotColors(iUnit,:))
        end
    end
    grid on, xlabel('humidity temperature [\circC]'), ylabel('rotation angle [\circ]'), legend(units)
    for iAx = 1:2
        subplot(2,2,2+iAx), hold on
        for iCal = 1:nCal
            for iUnit = 1:nUnits
                plot(humGrid, rgbThermalTrans(:,iAx,iCal,iUnit), plotStyles{iCal}, 'color', plotColors(iUnit,:))
            end
        end
        grid on, xlabel('humidity temperature [\circC]'), ylabel(sprintf('%s translation', transLabels{iAx})), legend(units)
    end
    sgtitle('RGB thermal transformation (solid - 1st CAL, dashed - 2nd CAL)')
    
    % RGB intrinsics - preparations
    rgbImageSize = [1920, 1080];
    nPts = 101; % 101 for contourf, 21 for quiver
    xRgbVec = linspace(1, rgbImageSize(1), nPts);
    yRgbVec = linspace(1, rgbImageSize(2), nPts);
    xRgb = repmat(xRgbVec, [nPts,1]);
    yRgb = repmat(yRgbVec', [1,nPts]);
    xLosRgbError = zeros(nPts, nPts, nUnits);
    yLosRgbError = zeros(nPts, nPts, nUnits);
    getTransMat = @(x) [x(1), -x(2), 0; x(2), x(1), 0; x(3), x(4), 1];
    for iUnit = 1:nUnits
        xLosRgb = zeros(nPts, nPts, nCal);
        yLosRgb = zeros(nPts, nPts, nCal);
        for iCal = 1:nCal
            K = Calibration.tables.calc.calcRgbIntrinsicMat(calData(iCal,iUnit).rgb.int.Kn, rgbImageSize);
            d = calData(iCal,iUnit).rgb.int.d;
            thermalCorrMat = getTransMat(interp1(humGrid, calData(iCal,iUnit).tables.rgbThermal, calData(1,iUnit).rgb.humCal));
            correctedPixels = [vec(xRgb), vec(yRgb), ones(numel(xRgb),1)]/thermalCorrMat; % applying inverse thermal correction
            undistortedPixels = du.math.undistortPoints(correctedPixels(:,1:2)', K, d, true);
            vertices = K\[undistortedPixels; ones(1,nPts^2)];
            vUnit = vertices./sqrt(sum(vertices.^2,1));
            xLosRgb(:,:,iCal) = reshape(atand(vUnit(1,:)./vUnit(3,:)), nPts, nPts);
            yLosRgb(:,:,iCal) = reshape(asind(vUnit(2,:)), nPts, nPts);
        end
        xLosRgbError(:,:,iUnit) = diff(xLosRgb, [], 3);
        yLosRgbError(:,:,iUnit) = diff(yLosRgb, [], 3);
    end
    % RGB intrinsics - plotting
    for iUnit = 1:nUnits
        figure('Name', 'RgbInt', 'Position', figPos1x1)
        contourf(xRgbVec, yRgbVec, sqrt(xLosRgbError(:,:,iUnit).^2+yLosRgbError(:,:,iUnit).^2))
        set(gca, 'ydir', 'reverse'), colorbar
        grid on, xlabel('x [pixels]'), ylabel('y [pixels]'), title(sprintf('RGB intrinsics aging for %s [\\circ]', units{iUnit}))
        
%         figure('Name', 'RgbInt', 'Position', figPos1x1)
%         quiver(vec(xRgb), vec(yRgb), vec(xLosRgbError(:,:,iUnit)), vec(yLosRgbError(:,:,iUnit)))
%         set(gca, 'ydir', 'reverse')
%         grid on, xlabel('x [pixels]'), ylabel('y [pixels]'), title(sprintf('RGB intrinsics aging for %s [\\circ]', units{iUnit}))
    end
    
    % RGB extrinsics - preparations
    extRotAngles = zeros(3, nCal, nUnits);
    extTranslations = zeros(3, nCal, nUnits);
    for iCal = 1:nCal
        for iUnit = 1:nUnits
            [xAlpha, yBeta, zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(calData(iCal,iUnit).rgb.ext.r);
            extRotAngles(:,iCal,iUnit) = [xAlpha, yBeta, zGamma]*180/pi;
            extTranslations(:,iCal,iUnit) = calData(iCal,iUnit).rgb.ext.t;
        end
    end
    plotStyles = {'-o', '-s', '-^'};
    % RGB extrinsics - plotting
    figure('Name', 'RgbExt', 'Position', figPos1x2)
    subplot(121), hold on
    for iAx = 1:size(extRotAngles,1)
        plot(squeeze(diff(extRotAngles(iAx,:,:))), plotStyles{iAx})
    end
    grid on, set(gca, 'XTick', 1:nUnits), set(gca, 'XTickLabel', units), ylabel('angle change [\circ]'), legend('xAlpha', 'yBeta', 'zGamma'), title('Extrinsic rotation')
    subplot(122), hold on
    for iAx = 1:size(extRotAngles,1)
        plot(squeeze(diff(extTranslations(iAx,:,:))), plotStyles{iAx})
    end
    grid on, set(gca, 'XTick', 1:nUnits), set(gca, 'XTickLabel', units), ylabel('translation change [mm]'), legend('x', 'y', 'z'), title('Extrinsic translation')
    sgtitle('RGB extrinsics aging')
    
end



