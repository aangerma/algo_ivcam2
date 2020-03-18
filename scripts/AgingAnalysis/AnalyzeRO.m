close all
clear all
clc

batch = 'open'; % 'bundle' or 'open'
flags.rtd = false;
flags.los = false;
flags.dsmCal = false;
flags.dfz = false;
flags.los2ang = true;

%%

t0 = load(sprintf('dataT0_%s.mat', batch), 'unitData', 'units');
RO1 = load(sprintf('dataRO1_%s.mat', batch), 'unitData', 'units');
assert(length(t0.unitData)==length(RO1.unitData), 'Batch size mismatch')
nUnits = length(t0.unitData);

%%

if flags.rtd
    figure(1), hold on
    for iUnit = 1:nUnits
        plot(0:2:94, RO1.unitData(iUnit).thermal.table(:,5) - t0.unitData(iUnit).thermal.table(:,5), '.-')
    end
    grid on, xlabel('LDD [deg]'), ylabel('change [mm]'), legend(t0.units), title('RTD table')
    
    figure(2), hold on
    for iUnit = 1:nUnits
        plot(0:2:94, RO1.unitData(iUnit).thermal.tableShort - t0.unitData(iUnit).thermal.tableShort, '.-')
    end
    grid on, xlabel('LDD [deg]'), ylabel('change [mm]'), legend(t0.units), title('RTD short table')
end

%%

if flags.los
    t0thermal = [t0.unitData.thermal];
    t0v2 = [t0thermal.v2Lims];
    t0v13 = [t0thermal.v13Lims];
    RO1thermal = [RO1.unitData.thermal];
    RO1v2 = [RO1thermal.v2Lims];
    RO1v13 = [RO1thermal.v13Lims];
    figure(11), subplot(131), hold on
    plot([1:nUnits, NaN, 1:nUnits], [t0v13(1,1:2:end), NaN, t0v13(1,2:2:end)], '-o')
    plot([1:nUnits, NaN, 1:nUnits], [RO1v13(1,1:2:end), NaN, RO1v13(1,2:2:end)], '-x')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('vBias1 [V]'), legend('T0', 'RO1'), title('PZR1')
    subplot(132), hold on
    plot([1:nUnits, NaN, 1:nUnits], [t0v2(1:2:end), NaN, t0v2(2:2:end)], '-o')
    plot([1:nUnits, NaN, 1:nUnits], [RO1v2(1:2:end), NaN, RO1v2(2:2:end)], '-x')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('vBias2 [V]'), legend('T0', 'RO1'), title('PZR2')
    subplot(133), hold on
    plot([1:nUnits, NaN, 1:nUnits], [t0v13(2,1:2:end), NaN, t0v13(2,2:2:end)], '-o')
    plot([1:nUnits, NaN, 1:nUnits], [RO1v13(2,1:2:end), NaN, RO1v13(2,2:2:end)], '-x')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('vBias3 [V]'), legend('T0', 'RO1'), title('PZR3')
    sgtitle('vBias thermal limits')
    
    tableInd = [1,3,2,4];
    ttls = {'X scale', 'X offset', 'Y scale', 'Y offset'};
    ylbls = {'change [1/deg]', 'change [deg]', 'change [1/deg]', 'change [deg]'};
    figure(12)
    for k = 1:4
        subplot(2,2,k), hold on
        for iUnit = 1:nUnits
            plot(RO1.unitData(iUnit).thermal.table(:,tableInd(k)) - t0.unitData(iUnit).thermal.table(:,tableInd(k)), '.-')
        end
        grid on, xlabel('LDD [deg]'), ylabel(ylbls{k}), legend(t0.units), title(ttls{k})
    end
    sgtitle('DSM table')
    
    tableInd = [1,3,2,4];
    ttls = {'X scale @ t0 (solid) & RO1 (dashed)', 'X offset @ t0 (solid) & RO1 (dashed)', 'Y scale @ t0 (solid) & RO1 (dashed)', 'Y offset @ t0 (solid) & RO1 (dashed)'};
    ylbls = {'scale [1/deg]', 'offset [deg]', 'scale [1/deg]', 'offset [deg]'};
    figure(13)
    for k = 1:4
        subplot(2,2,k), hold on
        for iUnit = 1:nUnits
            h(iUnit) = plot(t0.unitData(iUnit).thermal.table(:,tableInd(k)), '.-');
        end
        for iUnit = 1:nUnits
            plot(RO1.unitData(iUnit).thermal.table(:,tableInd(k)), '.--', 'color', get(h(iUnit), 'color'))
        end
        grid on, xlabel('LDD [deg]'), ylabel(ylbls{k}), legend(t0.units), title(ttls{k})
    end
    sgtitle('DSM table')
    
    figure(14)
    for k = 1:3
        subplot(1,3,k), hold on
        for iUnit = 1:nUnits
            h(iUnit) = plot(t0.unitData(iUnit).sensors.humThermal, t0.unitData(iUnit).sensors.vBiasThermal(k,:), '-');
        end
        for iUnit = 1:nUnits
            plot(RO1.unitData(iUnit).sensors.humThermal, RO1.unitData(iUnit).sensors.vBiasThermal(k,:), '--', 'color', get(h(iUnit), 'color'))
        end
        grid on, xlabel('HUM [deg]'), ylabel(sprintf('vBias%d [V]',k)), legend(t0.units)
        sgtitle('vBias vs. HUM (t0 - solid, RO1 - dashed)')
    end
    
    t0proj = [t0.unitData.proj];
    t0left = [t0proj.leftLims];
    t0right = [t0proj.rightLims];
    t0top = [t0proj.topLims];
    t0bottom = [t0proj.bottomLims];
    RO1proj = [RO1.unitData.proj];
    RO1left = [RO1proj.leftLims];
    RO1right = [RO1proj.rightLims];
    RO1top = [RO1proj.topLims];
    RO1bottom = [RO1proj.bottomLims];
    figure(15)
    subplot(221), hold on
    plot(1:nUnits, RO1left(1:2:end)-t0left(1:2:end), '-o')
    plot(1:nUnits, RO1left(2:2:end)-t0left(2:2:end), '-o')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [DU]'), legend('min', 'max'), title('Left projection limit')
    subplot(222), hold on
    plot(1:nUnits, RO1right(1:2:end)-t0right(1:2:end), '-o')
    plot(1:nUnits, RO1right(2:2:end)-t0right(2:2:end), '-o')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [DU]'), legend('min', 'max'), title('Right projection limit')
    subplot(223), hold on
    plot(1:nUnits, RO1top(1:2:end)-t0top(1:2:end), '-o')
    plot(1:nUnits, RO1top(2:2:end)-t0top(2:2:end), '-o')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [DU]'), legend('min', 'max'), title('Top projection limit')
    subplot(224), hold on
    plot(1:nUnits, RO1bottom(1:2:end)-t0bottom(1:2:end), '-o')
    plot(1:nUnits, RO1bottom(2:2:end)-t0bottom(2:2:end), '-o')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [DU]'), legend('min', 'max'), title('Bottom projection limit')
end

%%

if flags.dsmCal
    t0dsm = [t0.unitData.dsm];
    t0xlims = [t0dsm.xLims];
    t0ylims = [t0dsm.yLims];
    t0xscale = [t0dsm.xScale];
    t0xoffset = [t0dsm.xOffset];
    t0yscale = [t0dsm.yScale];
    t0rest = [t0dsm.losAtMirrorRest];
    t0yoffset = [t0dsm.yOffset];
    RO1dsm = [RO1.unitData.dsm];
    RO1xlims = [RO1dsm.xLims];
    RO1ylims = [RO1dsm.yLims];
    RO1xscale = [RO1dsm.xScale];
    RO1xoffset = [RO1dsm.xOffset];
    RO1yscale = [RO1dsm.yScale];
    RO1yoffset = [RO1dsm.yOffset];
    RO1rest = [RO1dsm.losAtMirrorRest];
    figure(21)
    subplot(121), hold on
    plot(1:nUnits, RO1xlims(1:2:end)-t0xlims(1:2:end), '-o');
    plot(1:nUnits, RO1xlims(2:2:end)-t0xlims(2:2:end), '-o');
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [DU]'), legend('min', 'max'), title('Horizontal')
    subplot(122), hold on
    plot(1:nUnits, RO1ylims(1:2:end)-t0ylims(1:2:end), '-o');
    plot(1:nUnits, RO1ylims(2:2:end)-t0ylims(2:2:end), '-o');
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [DU]'), legend('min', 'max'), title('Vertical')
    sgtitle('Visited angles during DSM cal')
    
    figure(22), hold on
    plot(1:nUnits, RO1rest(1:2:end)-t0rest(1:2:end), '-o');
    plot(1:nUnits, RO1rest(2:2:end)-t0rest(2:2:end), '-o');
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [DU]'), legend('x', 'y'), title('LOS @ mirror rest')
end

%%

if flags.dfz
    t0dfz = [t0.unitData.dfz];
    t0fov = [t0dfz.fov];
    t0delay = [t0dfz.systemDelay];
    RO1dfz = [RO1.unitData.dfz];
    RO1fov = [RO1dfz.fov];
    RO1delay = [RO1dfz.systemDelay];
    figure(31)
    subplot(121), hold on
    plot(1:nUnits, RO1fov(1:10:end)-t0fov(1:10:end), '-o')
    plot(1:nUnits, RO1fov(6:10:end)-t0fov(6:10:end), '-o')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [deg]'), legend('x', 'y'), title('FOV factor')
    subplot(122), hold on
    plot(1:nUnits, RO1delay(1:3:end)-t0delay(1:3:end), '-o')
    grid on, set(gca,'xtick',1:nUnits), set(gca,'xticklabel',t0.units), ylabel('change [mm]'), title('System delay')
end

%%

if flags.los2ang
    nLos = 31;
    midInd = ceil(nLos/2);
    xFovHalf = 27;
    yFovHalf = 23;
    xLosVec = linspace(-xFovHalf,xFovHalf,nLos);
    yLosVec = linspace(-yFovHalf,yFovHalf,nLos);
    xLos = repmat(xLosVec, [nLos,1]);
    yLos = repmat(yLosVec', [1,nLos]);
    fovexNom = [0.080740546190841, 0.003021202017618, -0.000127636017763, 0.000003583535017];
    angles2xyz = @(angx,angy) [cosd(angy).*sind(angx), sind(angy), cosd(angy).*cosd(angx)];
    lddVec = 10:5:60;
    midLddInd = ceil(length(lddVec)/2);
    for iUnit = 1:nUnits
        fprintf('Processing %s... ', t0.units{iUnit});
        t = tic;
        data = t0.unitData(iUnit);
        regs.FRMW = struct('atlMinVbias1', data.thermal.v13Lims(1,1), 'atlMinVbias2', data.thermal.v2Lims(1), 'atlMinVbias3', data.thermal.v13Lims(2,1),...
                           'atlMaxVbias1', data.thermal.v13Lims(1,2), 'atlMaxVbias2', data.thermal.v2Lims(2), 'atlMaxVbias3', data.thermal.v13Lims(2,2),...
                           'polyVars', [0, data.dfz.polyVar, 0], 'pitchFixFactor', data.dfz.pitchFixFactor, 'undistAngHorz', data.dfz.fineCorrHorz, 'undistAngVert', zeros(1,4),...
                           'mirrorMovmentMode', 1, 'xfov', data.dfz.fov(1), 'yfov', data.dfz.fov(6), 'projectionYshear', 0, 'laserangleH', data.dfz.laserAngle(1), 'laserangleV', data.dfz.laserAngle(2),...
                           'fovexExistenceFlag', true, 'fovexNominal', fovexNom, 'fovexCenter', [0,0], 'fovexLensDistFlag', false);
        t0xLosTrue = repmat(0*xLos,[1,1,length(lddVec)]);
        t0yLosTrue = repmat(0*xLos,[1,1,length(lddVec)]);
        for iLdd = 1:length(lddVec)
%             [xLosTrue, yLosTrue] = CalcTrueLos(regs, data.thermal.table, data.dfz.tpsModel.tpsUndistModel, xLos, yLos, lddVec(iLdd));
%             figure(41)
%             subplot(121), imagesc(xLosVec, yLosVec, xLos-xLosTrue), colorbar, xlabel('LOS x [deg]'), ylabel('LOS y [deg]'), title('LOS X error [deg]'), set(gca,'clim',[-3.5,1])
%             subplot(122), imagesc(xLosVec, yLosVec, yLos-yLosTrue), colorbar, xlabel('LOS x [deg]'), ylabel('LOS y [deg]'), title('LOS Y error [deg]'), set(gca,'clim',[-2,1])
%             shg
            [t0xLosTrue(:,:,iLdd), t0yLosTrue(:,:,iLdd)] = CalcTrueLos(regs, data.thermal.table, data.dfz.tpsModel.tpsUndistModel, xLos, yLos, lddVec(iLdd));
        end
        
        data = RO1.unitData(iUnit);
        regs.FRMW = struct('atlMinVbias1', data.thermal.v13Lims(1,1), 'atlMinVbias2', data.thermal.v2Lims(1), 'atlMinVbias3', data.thermal.v13Lims(2,1),...
                           'atlMaxVbias1', data.thermal.v13Lims(1,2), 'atlMaxVbias2', data.thermal.v2Lims(2), 'atlMaxVbias3', data.thermal.v13Lims(2,2),...
                           'polyVars', [0, data.dfz.polyVar, 0], 'pitchFixFactor', data.dfz.pitchFixFactor, 'undistAngHorz', data.dfz.fineCorrHorz, 'undistAngVert', zeros(1,4),...
                           'mirrorMovmentMode', 1, 'xfov', data.dfz.fov(1), 'yfov', data.dfz.fov(6), 'projectionYshear', 0, 'laserangleH', data.dfz.laserAngle(1), 'laserangleV', data.dfz.laserAngle(2),...
                           'fovexExistenceFlag', true, 'fovexNominal', fovexNom, 'fovexCenter', [0,0], 'fovexLensDistFlag', false);
        RO1xLosTrue = repmat(0*xLos,[1,1,length(lddVec)]);
        RO1yLosTrue = repmat(0*xLos,[1,1,length(lddVec)]);
        for iLdd = 1:length(lddVec)
%             [xLosTrue, yLosTrue] = CalcTrueLos(regs, data.thermal.table, data.dfz.tpsModel.tpsUndistModel, xLos, yLos, lddVec(iLdd));
%             figure(41)
%             subplot(121), imagesc(xLosVec, yLosVec, xLos-xLosTrue), colorbar, xlabel('LOS x [deg]'), ylabel('LOS y [deg]'), title('LOS X error [deg]'), set(gca,'clim',[-3.5,1])
%             subplot(122), imagesc(xLosVec, yLosVec, yLos-yLosTrue), colorbar, xlabel('LOS x [deg]'), ylabel('LOS y [deg]'), title('LOS Y error [deg]'), set(gca,'clim',[-2,1])
%             shg
            [RO1xLosTrue(:,:,iLdd), RO1yLosTrue(:,:,iLdd)] = CalcTrueLos(regs, data.thermal.table, data.dfz.tpsModel.tpsUndistModel, xLos, yLos, lddVec(iLdd));
        end
        
%         figure(40+iUnit)
%         subplot(121), hold on
%         h(1) = plot(lddVec, xLos(midInd,1) - squeeze(t0xLosTrue(midInd,1,:)), '-o');
%         h(2) = plot(lddVec, xLos(midInd,midInd) - squeeze(t0xLosTrue(midInd,midInd,:)), '-o');
%         h(3) = plot(lddVec, xLos(midInd,nLos) - squeeze(t0xLosTrue(midInd,nLos,:)), '-o');
%         plot(lddVec, xLos(midInd,1) - squeeze(RO1xLosTrue(midInd,1,:)), '--^', 'color', get(h(1),'color'));
%         plot(lddVec, xLos(midInd,midInd) - squeeze(RO1xLosTrue(midInd,midInd,:)), '--^', 'color', get(h(2),'color'));
%         plot(lddVec, xLos(midInd,nLos) - squeeze(RO1xLosTrue(midInd,nLos,:)), '--^', 'color', get(h(3),'color'));
%         grid on, xlabel('LDD [deg]'), ylabel('error [deg]'), legend(sprintf('x=%.1f[deg]',xLosVec(1)), sprintf('x=%.1f[deg]',xLosVec(midInd)), sprintf('x=%.1f[deg]',xLosVec(nLos))), title(sprintf('X error for y=%.1f[deg]', yLosVec(midInd)))
% 
%         subplot(122), hold on
%         h(1) = plot(lddVec, yLos(1,midInd) - squeeze(t0yLosTrue(1,midInd,:)), '-o');
%         h(2) = plot(lddVec, yLos(midInd,midInd) - squeeze(t0yLosTrue(midInd,midInd,:)), '-o');
%         h(3) = plot(lddVec, yLos(nLos,midInd) - squeeze(t0yLosTrue(nLos,midInd,:)), '-o');
%         plot(lddVec, yLos(1,midInd) - squeeze(RO1yLosTrue(1,midInd,:)), '--^', 'color', get(h(1),'color'));
%         plot(lddVec, yLos(midInd,midInd) - squeeze(RO1yLosTrue(midInd,midInd,:)), '--^', 'color', get(h(2),'color'));
%         plot(lddVec, yLos(nLos,midInd) - squeeze(RO1yLosTrue(nLos,midInd,:)), '--^', 'color', get(h(3),'color'));
%         grid on, xlabel('LDD [deg]'), ylabel('error [deg]'), legend(sprintf('y=%.1f[deg]',yLosVec(1)), sprintf('y=%.1f[deg]',yLosVec(midInd)), sprintf('y=%.1f[deg]',yLosVec(nLos))), title(sprintf('Y error for x=%.1f[deg]', xLosVec(midInd)))
%         sgtitle(sprintf('%s: LOS errors @ t0 (solid) and RO1 (dashed)', t0.units{iUnit}))

%         xLosAging = t0xLosTrue - RO1xLosTrue;
%         yLosAging = t0yLosTrue - RO1yLosTrue;
%         figure(44+iUnit)
%         subplot(121), hold on
%         plot(lddVec, squeeze(xLosAging(midInd,1,:)), '-o')
%         plot(lddVec, squeeze(xLosAging(midInd,midInd,:)), '-o')
%         plot(lddVec, squeeze(xLosAging(midInd,nLos,:)), '-o')
%         grid on, xlabel('LDD [deg]'), ylabel('change [deg]'), legend(sprintf('x=%.1f[deg]',xLosVec(1)), sprintf('x=%.1f[deg]',xLosVec(midInd)), sprintf('x=%.1f[deg]',xLosVec(nLos))), title(sprintf('X change for y=%.1f[deg]', yLosVec(midInd)))
%         subplot(122), hold on
%         plot(lddVec, squeeze(yLosAging(1,midInd,:)), '-o')
%         plot(lddVec, squeeze(yLosAging(midInd,midInd,:)), '-o')
%         plot(lddVec, squeeze(yLosAging(nLos,midInd,:)), '-o')
%         grid on, xlabel('LDD [deg]'), ylabel('change [deg]'), legend(sprintf('y=%.1f[deg]',yLosVec(1)), sprintf('y=%.1f[deg]',yLosVec(midInd)), sprintf('y=%.1f[deg]',yLosVec(nLos))), title(sprintf('Y change for x=%.1f[deg]', xLosVec(midInd)))
%         sgtitle(sprintf('LOS aging for unit %s', t0.units{iUnit}))
        
%         figure(48+iUnit)
%         subplot(121), hold on
%         plot(xLosVec, squeeze(xLosAging(1,:,midLddInd)), '-o')
%         plot(xLosVec, squeeze(xLosAging(midInd,:,midLddInd)), '-o')
%         plot(xLosVec, squeeze(xLosAging(nLos,:,midLddInd)), '-o')
%         grid on, xlabel('x [deg]'), ylabel('change [deg]'), legend(sprintf('y=%.1f[deg]',yLosVec(1)), sprintf('y=%.1f[deg]',yLosVec(midInd)), sprintf('y=%.1f[deg]',yLosVec(nLos))), title(sprintf('X change for T=%.1f[deg]', lddVec(midLddInd)))
%         subplot(122), hold on
%         plot(yLosVec, squeeze(yLosAging(:,1,midLddInd)), '-o')
%         plot(yLosVec, squeeze(yLosAging(:,midInd,midLddInd)), '-o')
%         plot(yLosVec, squeeze(yLosAging(:,nLos,midLddInd)), '-o')
%         grid on, xlabel('y [deg]'), ylabel('change [deg]'), legend(sprintf('x=%.1f[deg]',xLosVec(1)), sprintf('x=%.1f[deg]',xLosVec(midInd)), sprintf('x=%.1f[deg]',xLosVec(nLos))), title(sprintf('Y change for T=%.1f[deg]', lddVec(midLddInd)))
%         sgtitle(sprintf('LOS aging for unit %s', t0.units{iUnit}))
        
%         figure(52+iUnit), hold on
%         quiver(vec(xLos), vec(yLos), vec(xLosAging(:,:,midLddInd)), vec(yLosAging(:,:,midLddInd)))
%         set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse')
%         grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('LOS aging for %s @ T=%.1f[deg]', t0.units{iUnit}, lddVec(midLddInd)))
%         
%         figure(56+iUnit), hold on
%         contour(xLosVec, yLosVec, sqrt(xLosAging(:,:,midLddInd).^2+yLosAging(:,:,midLddInd).^2));
%         set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
%         grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('LOS aging for %s @ T=%.1f[deg]', t0.units{iUnit}, lddVec(midLddInd)))
        
        for iLdd = 1:length(lddVec)
            xLosNew(:,:,iLdd) = reshape(griddata(vec(RO1xLosTrue(:,:,iLdd)), vec(RO1yLosTrue(:,:,iLdd)), vec(xLos), vec(t0xLosTrue(:,:,iLdd)), vec(t0yLosTrue(:,:,iLdd))), nLos, nLos);
            yLosNew(:,:,iLdd) = reshape(griddata(vec(RO1xLosTrue(:,:,iLdd)), vec(RO1yLosTrue(:,:,iLdd)), vec(yLos), vec(t0xLosTrue(:,:,iLdd)), vec(t0yLosTrue(:,:,iLdd))), nLos, nLos);
        end
        xLosAging = xLosNew-xLos;
        yLosAging = yLosNew-yLos;
        
        figure(60+iUnit), hold on
        quiver(vec(xLos), vec(yLos), vec(xLosAging(:,:,midLddInd)), vec(yLosAging(:,:,midLddInd)))
        set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse')
        grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('LOS aging for %s @ T=%.1f[deg]', t0.units{iUnit}, lddVec(midLddInd)))
        
        figure(64+iUnit), hold on
        contour(xLosVec, yLosVec, sqrt(xLosAging(:,:,midLddInd).^2+yLosAging(:,:,midLddInd).^2));
        set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
        grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('LOS aging for %s @ T=%.1f[deg]', t0.units{iUnit}, lddVec(midLddInd)))

        fprintf('Done (%.1f sec)\n', toc(t));
    end
end

%%

% unitData.pzr.vSenseModel

% unitData.sensors.lddDFZ
% unitData.sensors.vddDFZ

% unitData.delays.zOffset
% unitData.delays.irOffset
% unitData.delays.zSlope
% unitData.delays.irSlope

% unitData.dfz.laserAngle
% unitData.dfz.rtdOverX
% unitData.dfz.rtdOverY

% unitData.roi.xMargins
% unitData.roi.yMargins

% unitData.rgb.int.Kn
% unitData.rgb.int.d
% unitData.rgb.ext.r
% unitData.rgb.ext.t
% unitData.rgb.humCal
% unitData.rgb.thermalTable









