close all
clear all
clc


%% Ground truth calculation

load('dataRepeatability.mat', 'coldData', 'hotData');

nLos = 31;
midInd = ceil(nLos/2);
xFovHalf = 27;
yFovHalf = 23;
xLosVec = linspace(-xFovHalf,xFovHalf,nLos);
yLosVec = linspace(-yFovHalf,yFovHalf,nLos);
xLos = repmat(xLosVec, [nLos,1]);
yLos = repmat(yLosVec', [1,nLos]);

lddVec = 10:5:60;
midLddInd = ceil(length(lddVec)/2);

for iCold = 1:length(coldData)
    fprintf('Processing cold ACC #%d... ', iCold);
    t = tic;
    data = coldData(iCold);
    for iLdd = 1:length(lddVec)
        [xLosTrueCold{iCold}(:,:,iLdd), yLosTrueCold{iCold}(:,:,iLdd)] = Utils.convert.MemsToTrueLos(data.regs, data.tables.thermal, data.tpsUndistModel, xLos, yLos, lddVec(iLdd));
    end
    fprintf('Done (%.1f sec)\n', toc(t));
end
for iHot = 1:length(coldData)
    fprintf('Processing hot ACC #%d... ', iHot);
    t = tic;
    data = hotData(iHot);
    for iLdd = 1:length(lddVec)
        [xLosTrueHot{iHot}(:,:,iLdd), yLosTrueHot{iHot}(:,:,iLdd)] = Utils.convert.MemsToTrueLos(data.regs, data.tables.thermal, data.tpsUndistModel, xLos, yLos, lddVec(iLdd));
    end
    fprintf('Done (%.1f sec)\n', toc(t));
end

%% Analyzing full pipe errors

figure

iCold = 1;
xLosError = xLos-xLosTrueCold{iCold}(:,:,midLddInd);
yLosError = yLos-yLosTrueCold{iCold}(:,:,midLddInd);
subplot(221)
quiver(vec(xLos), vec(yLos), vec(xLosError), vec(yLosError))
set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', coldData(iCold).regs.FRMW.dfzCalibrationLddTemp))
xlim([-1,1]*xFovHalf), ylim([-1,1]*yFovHalf)
subplot(222)
contourf(xLosVec, yLosVec, sqrt(xLosError.^2+yLosError.^2));
set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', coldData(iCold).regs.FRMW.dfzCalibrationLddTemp))

iHot = 3;
xLosError = xLos-xLosTrueHot{iHot}(:,:,midLddInd);
yLosError = yLos-yLosTrueHot{iHot}(:,:,midLddInd);
subplot(223)
quiver(vec(xLos), vec(yLos), vec(xLosError), vec(yLosError))
set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', hotData(iHot).regs.FRMW.dfzCalibrationLddTemp))
xlim([-1,1]*xFovHalf), ylim([-1,1]*yFovHalf)
subplot(224)
contourf(xLosVec, yLosVec, sqrt(xLosError.^2+yLosError.^2));
set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', hotData(iHot).regs.FRMW.dfzCalibrationLddTemp))

sgtitle(sprintf('LOS error @ T=%.1f[deg]', lddVec(midLddInd)))

%% Calculating coarse errors

nDsm = 101;
midInd = ceil(nDsm/2);
dsmHalfRange = 2047;
xDsmVec = linspace(-dsmHalfRange,dsmHalfRange,nDsm);
yDsmVec = linspace(-dsmHalfRange,dsmHalfRange,nDsm);
dsmX = repmat(xDsmVec, [nDsm,1]);
dsmY = repmat(yDsmVec', [1,nDsm]);

for iCold = 1:length(coldData)
    data = coldData(iCold);
    [angx, angy] = Calibration.Undist.applyPolyUndistAndPitchFix(dsmX, dsmY, data.regs);
    xDsmTrueCold{iCold} = double(angx);
    yDsmTrueCold{iCold} = double(angy);
end
for iHot = 1:length(hotData)
    data = hotData(iHot);
    [angx, angy] = Calibration.Undist.applyPolyUndistAndPitchFix(dsmX, dsmY, data.regs);
    xDsmTrueHot{iHot} = double(angx);
    yDsmTrueHot{iHot} = double(angy);
end

%% Analyzing coarse errors

for iCold = 1:length(coldData)
    xDsmNewCold{iCold} = reshape(griddata(vec(xDsmTrueCold{iCold}), vec(yDsmTrueCold{iCold}), vec(dsmX), vec(xDsmTrueCold{1}), vec(yDsmTrueCold{1})), nDsm, nDsm);
    yDsmNewCold{iCold} = reshape(griddata(vec(xDsmTrueCold{iCold}), vec(yDsmTrueCold{iCold}), vec(dsmY), vec(xDsmTrueCold{1}), vec(yDsmTrueCold{1})), nDsm, nDsm);
end
for iHot = 1:length(hotData)
    xDsmNewHot{iHot} = reshape(griddata(vec(xDsmTrueHot{iHot}), vec(yDsmTrueHot{iHot}), vec(dsmX), vec(xDsmTrueCold{1}), vec(yDsmTrueCold{1})), nDsm, nDsm);
    yDsmNewHot{iHot} = reshape(griddata(vec(xDsmTrueHot{iHot}), vec(yDsmTrueHot{iHot}), vec(dsmY), vec(xDsmTrueCold{1}), vec(yDsmTrueCold{1})), nDsm, nDsm);
end

ii = find(xDsmVec>=-2010 & xDsmVec<=2010);
figure
for iCold = 1:length(coldData)
    xDsmError = dsmX(ii,ii)-double(xDsmNewCold{iCold}(ii,ii));
    yDsmError = dsmY(ii,ii)-double(yDsmNewCold{iCold}(ii,ii));
    subplot(3,2,2*iCold-1)
    contourf(xDsmVec(ii), yDsmVec(ii), sqrt(xDsmError.^2+yDsmError.^2));
%     quiver(vec(dsmX(ii,ii)), vec(dsmY(ii,ii)), vec(xDsmError), vec(yDsmError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('DSM x [deg]'), ylabel('DSM y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', coldData(iCold).regs.FRMW.dfzCalibrationLddTemp))
    
    xDsmError = dsmX(ii,ii)-double(xDsmNewHot{iCold}(ii,ii));
    yDsmError = dsmY(ii,ii)-double(yDsmNewHot{iCold}(ii,ii));
    subplot(3,2,2*iCold)
    contourf(xDsmVec(ii), yDsmVec(ii), sqrt(xDsmError.^2+yDsmError.^2));
%     quiver(vec(dsmX(ii,ii)), vec(dsmY(ii,ii)), vec(xDsmError), vec(yDsmError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('DSM x [deg]'), ylabel('DSM y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', hotData(iCold).regs.FRMW.dfzCalibrationLddTemp))
end
sgtitle('Repeatability DSM errors w.r.t. first cold ACC')

%% Analyzing FOV

coldFov = [coldData(1).regs.FRMW.xfov(1), coldData(2).regs.FRMW.xfov(1), coldData(3).regs.FRMW.xfov(1); coldData(1).regs.FRMW.yfov(1), coldData(2).regs.FRMW.yfov(1), coldData(3).regs.FRMW.yfov(1)];
hotFov = [hotData(1).regs.FRMW.xfov(1), hotData(2).regs.FRMW.xfov(1), hotData(3).regs.FRMW.xfov(1); hotData(1).regs.FRMW.yfov(1), hotData(2).regs.FRMW.yfov(1), hotData(3).regs.FRMW.yfov(1)];
figure
subplot(121)
hold on
plot(coldFov(1,:), '-o')
plot(hotFov(1,:), '-s')
grid on, xlabel('#ACC'), ylabel('DFZ FOV'), legend('cold', 'hot'), title('X')
subplot(122)
hold on
plot(coldFov(2,:), '-o')
plot(hotFov(2,:), '-s')
grid on, xlabel('#ACC'), ylabel('DFZ FOV'), legend('cold', 'hot'), title('Y')

%% Analyzing vBias during DFZ

vBiasCold =[1.8176 1.8434 1.9742;...
            1.8150 1.8432 1.9724;...
            1.8120 1.8383 1.9681];
vBiasHot = [2.0360 2.0721 2.2039;...
            2.0391 2.0756 2.2079;...
            2.0426 2.0774 2.2116];
humCold = [14.66, 14.91, 13.88];
humHot = [47.59, 48.00, 48.03];

figure
for iPzr = 1:3
    hAx = subplot(1,4,iPzr);
    yyaxis(hAx, 'left')
    plot(vBiasCold(:, iPzr), '-o')
    ylabel('vBias during cold DFZ [V]')
    yyaxis(hAx, 'right')
    plot(vBiasHot(:, iPzr), '-o')
    ylabel('vBias during hot DFZ [V]')
    grid on, xlabel('#ACC'), title(sprintf('PZR %d', iPzr))
end
hAx = subplot(1,4,4);
yyaxis(hAx, 'left')
plot(humCold, '-o')
ylabel('SHTW2 during cold DFZ [C]')
yyaxis(hAx, 'right')
plot(humHot, '-o')
ylabel('SHTW2 during hot DFZ [C]')
grid on, xlabel('#ACC'), title('Humidity temperature')

%% Calculating TPS

nAng = 101;
xAngHalfRange = 36;
yAngHalfRange = 27.5;
xAngVec = linspace(-xAngHalfRange,xAngHalfRange,nAng);
yAngVec = linspace(-yAngHalfRange,yAngHalfRange,nAng);
xAng = repmat(xAngVec, [nAng,1]);
yAng = repmat(yAngVec', [1,nAng]);
angles2xyz = @(angx,angy) [cosd(angy).*sind(angx), sind(angy), cosd(angy).*cosd(angx)];
for iCold = 1:length(coldData)
    data = coldData(iCold);
    vUnit = Calibration.Undist.undistByTPSModel(angles2xyz(vec(xAng), vec(yAng)), data.tpsUndistModel);
    xAngTrueCold{iCold} = reshape(atand(vUnit(:,1)./vUnit(:,3)), nAng, nAng);
    yAngTrueCold{iCold} = reshape(asind(vUnit(:,2)), nAng, nAng);
end
for iHot = 1:length(hotData)
    data = hotData(iHot);
    vUnit = Calibration.Undist.undistByTPSModel(angles2xyz(vec(xAng), vec(yAng)), data.tpsUndistModel);
    xAngTrueHot{iHot} = reshape(atand(vUnit(:,1)./vUnit(:,3)), nAng, nAng);
    yAngTrueHot{iHot} = reshape(asind(vUnit(:,2)), nAng, nAng);
end

for iCold = 1:length(coldData)
    xAngError = xAng-xAngTrueCold{iCold};
    yAngError = yAng-yAngTrueCold{iCold};
    figure
    set(gcf, 'Position', [680         558        1086         420])
    subplot(121)
    quiver(vec(xAng), vec(yAng), vec(xAngError), vec(yAngError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('yaw (x) [deg]'), ylabel('elevation (y) [deg]')
    subplot(122)
    contourf(xAngVec, yAngVec, sqrt(xAngError.^2+yAngError.^2))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('yaw (x) [deg]'), ylabel('elevation (y) [deg]')
    sgtitle(sprintf('Outbound ray direction errors (before TPS model) in cold ACC #%d', iCold))
end
for iHot = 1:length(hotData)
    xAngError = xAng-xAngTrueHot{iHot};
    yAngError = yAng-yAngTrueHot{iHot};
    figure
    set(gcf, 'Position', [680         558        1086         420])
    subplot(121)
    quiver(vec(xAng), vec(yAng), vec(xAngError), vec(yAngError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('yaw (x) [deg]'), ylabel('elevation (y) [deg]')
    subplot(122)
    contourf(xAngVec, yAngVec, sqrt(xAngError.^2+yAngError.^2))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('yaw (x) [deg]'), ylabel('elevation (y) [deg]')
    sgtitle(sprintf('Outbound ray direction errors (before TPS model) in hot ACC #%d', iHot))
end

%% Analyzing TPS

for iCold = 1:length(coldData)
    xAngNewCold{iCold} = reshape(griddata(vec(xAngTrueCold{iCold}), vec(yAngTrueCold{iCold}), vec(xAng), vec(xAngTrueCold{1}), vec(yAngTrueCold{1})), nAng, nAng);
    yAngNewCold{iCold} = reshape(griddata(vec(xAngTrueCold{iCold}), vec(yAngTrueCold{iCold}), vec(yAng), vec(xAngTrueCold{1}), vec(yAngTrueCold{1})), nAng, nAng);
end
for iHot = 1:length(hotData)
    xAngNewHot{iHot} = reshape(griddata(vec(xAngTrueHot{iHot}), vec(yAngTrueHot{iHot}), vec(xAng), vec(xAngTrueCold{1}), vec(yAngTrueCold{1})), nAng, nAng);
    yAngNewHot{iHot} = reshape(griddata(vec(xAngTrueHot{iHot}), vec(yAngTrueHot{iHot}), vec(yAng), vec(xAngTrueCold{1}), vec(yAngTrueCold{1})), nAng, nAng);
end

ii = find(abs(xAngVec)<=0.98*xAngHalfRange);
jj = find(abs(yAngVec)<=0.98*yAngHalfRange);
takeRoi80 = false;
figure
for iCold = 1:length(coldData)
    xAngError = xAng(jj,ii)-double(xAngNewCold{iCold}(jj,ii));
    yAngError = yAng(jj,ii)-double(yAngNewCold{iCold}(jj,ii));
    if takeRoi80
        xAngError(xAng(jj,ii).^2+yAng(jj,ii).^2 > 0.8^2*max(max(xAng(jj,ii).^2+yAng(jj,ii).^2))) = 0;
        yAngError(xAng(jj,ii).^2+yAng(jj,ii).^2 > 0.8^2*max(max(xAng(jj,ii).^2+yAng(jj,ii).^2))) = 0;
    end
    subplot(3,2,2*iCold-1)
    contourf(xAngVec(ii), yAngVec(jj), sqrt(xAngError.^2+yAngError.^2));
    accuratePercCold(iCold) = sum(sum(sqrt(xAngError.^2+yAngError.^2)<=0.05))/numel(xAngError);
    %     quiver(vec(xAng(ii,ii)), vec(yAng(ii,ii)), vec(xAngError), vec(yAngError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('yaw (x) [deg]'), ylabel('elevation (y) [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', coldData(iCold).regs.FRMW.dfzCalibrationLddTemp))
    
    xAngError = xAng(jj,ii)-double(xAngNewHot{iCold}(jj,ii));
    yAngError = yAng(jj,ii)-double(yAngNewHot{iCold}(jj,ii));
    if takeRoi80
        xAngError(xAng(jj,ii).^2+yAng(jj,ii).^2 > 0.8^2*max(max(xAng(jj,ii).^2+yAng(jj,ii).^2))) = 0;
        yAngError(xAng(jj,ii).^2+yAng(jj,ii).^2 > 0.8^2*max(max(xAng(jj,ii).^2+yAng(jj,ii).^2))) = 0;
    end
    subplot(3,2,2*iCold)
    contourf(xAngVec(ii), yAngVec(jj), sqrt(xAngError.^2+yAngError.^2));
    accuratePercHot(iCold) = sum(sum(sqrt(xAngError.^2+yAngError.^2)<=0.05))/numel(xAngError);
%     quiver(vec(xAng(ii,ii)), vec(yAng(ii,ii)), vec(xAngError), vec(yAngError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('yaw (x) [deg]'), ylabel('elevation (y) [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', hotData(iCold).regs.FRMW.dfzCalibrationLddTemp))
end
sgtitle('Repeatability fine errors w.r.t. first cold ACC')

%% Calculate full ACC

nDsm = 101;
midInd = ceil(nDsm/2);
dsmHalfRange = 2047;
xDsmVec = linspace(-dsmHalfRange,dsmHalfRange,nDsm);
yDsmVec = linspace(-dsmHalfRange,dsmHalfRange,nDsm);
dsmX = repmat(xDsmVec, [nDsm,1]);
dsmY = repmat(yDsmVec', [1,nDsm]);

for iCold = 1:length(coldData)
    data = coldData(iCold);
    [losX, losY] = Utils.convert.DsmToTrueLos(data.regs, data.tpsUndistModel, dsmX, dsmY);
    xLosTrueCold{iCold} = double(losX);
    yLosTrueCold{iCold} = double(losY);
end
for iHot = 1:length(coldData)
    data = hotData(iHot);
    [losX, losY] = Utils.convert.DsmToTrueLos(data.regs, data.tpsUndistModel, dsmX, dsmY);
    xLosTrueHot{iHot} = double(losX);
    yLosTrueHot{iHot} = double(losY);
end

%% Analyzing full ACC

refAcc = 'cold'; % 'cold' or 'hot'
errAx = 'x'; % 'x' or 'y' or 'xycon'

switch refAcc
    case 'cold'
        for iCold = 1:length(coldData)
            xDsmNewCold{iCold} = reshape(griddata(vec(xLosTrueCold{iCold}), vec(yLosTrueCold{iCold}), vec(dsmX), vec(xLosTrueCold{1}), vec(yLosTrueCold{1})), nDsm, nDsm);
            yDsmNewCold{iCold} = reshape(griddata(vec(xLosTrueCold{iCold}), vec(yLosTrueCold{iCold}), vec(dsmY), vec(xLosTrueCold{1}), vec(yLosTrueCold{1})), nDsm, nDsm);
        end
        for iHot = 1:length(hotData)
            xDsmNewHot{iHot} = reshape(griddata(vec(xLosTrueHot{iHot}), vec(yLosTrueHot{iHot}), vec(dsmX), vec(xLosTrueCold{1}), vec(yLosTrueCold{1})), nDsm, nDsm);
            yDsmNewHot{iHot} = reshape(griddata(vec(xLosTrueHot{iHot}), vec(yLosTrueHot{iHot}), vec(dsmY), vec(xLosTrueCold{1}), vec(yLosTrueCold{1})), nDsm, nDsm);
        end
    case 'hot'
        for iCold = 1:length(coldData)
            xDsmNewCold{iCold} = reshape(griddata(vec(xLosTrueCold{iCold}), vec(yLosTrueCold{iCold}), vec(dsmX), vec(xLosTrueHot{1}), vec(yLosTrueHot{1})), nDsm, nDsm);
            yDsmNewCold{iCold} = reshape(griddata(vec(xLosTrueCold{iCold}), vec(yLosTrueCold{iCold}), vec(dsmY), vec(xLosTrueHot{1}), vec(yLosTrueHot{1})), nDsm, nDsm);
        end
        for iHot = 1:length(hotData)
            xDsmNewHot{iHot} = reshape(griddata(vec(xLosTrueHot{iHot}), vec(yLosTrueHot{iHot}), vec(dsmX), vec(xLosTrueHot{1}), vec(yLosTrueHot{1})), nDsm, nDsm);
            yDsmNewHot{iHot} = reshape(griddata(vec(xLosTrueHot{iHot}), vec(yLosTrueHot{iHot}), vec(dsmY), vec(xLosTrueHot{1}), vec(yLosTrueHot{1})), nDsm, nDsm);
        end
end

xFovHalf = 27;
yFovHalf = 23;
ii = (abs(mean(xLosTrueCold{1},1))<=xFovHalf) & (abs(mean(xLosTrueCold{2},1))<=xFovHalf) & (abs(mean(xLosTrueCold{3},1))<=xFovHalf);
jj = (abs(mean(yLosTrueCold{1},2))<=yFovHalf) & (abs(mean(yLosTrueCold{2},2))<=yFovHalf) & (abs(mean(yLosTrueCold{3},2))<=yFovHalf);
figure
for iCold = 1:length(coldData)
    xDsmError = dsmX(jj,ii)-double(xDsmNewCold{iCold}(jj,ii));
    yDsmError = dsmY(jj,ii)-double(yDsmNewCold{iCold}(jj,ii));
    subplot(3,2,2*iCold-1)
    contourf(xDsmVec(ii), yDsmVec(jj), sqrt(contains(errAx,'x')*xDsmError.^2+contains(errAx,'y')*yDsmError.^2));
%     quiver(vec(dsmX(ii,ii)), vec(dsmY(ii,ii)), vec(xDsmError), vec(yDsmError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('DSM x [deg]'), ylabel('DSM y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', coldData(iCold).regs.FRMW.dfzCalibrationLddTemp))
    
    xDsmError = dsmX(jj,ii)-double(xDsmNewHot{iCold}(jj,ii));
    yDsmError = dsmY(jj,ii)-double(yDsmNewHot{iCold}(jj,ii));
    subplot(3,2,2*iCold)
    contourf(xDsmVec(ii), yDsmVec(jj), sqrt(contains(errAx,'x')*xDsmError.^2+contains(errAx,'y')*yDsmError.^2));
%     quiver(vec(dsmX(ii,ii)), vec(dsmY(ii,ii)), vec(xDsmError), vec(yDsmError))
    set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
    grid on, xlabel('DSM x [deg]'), ylabel('DSM y [deg]'), title(sprintf('DFZ calibration @ T=%.1fC', hotData(iHot).regs.FRMW.dfzCalibrationLddTemp))
end
sgtitle('Repeatability ACC errors w.r.t. first cold ACC')

%%

% for iUnit = 1:1   
%     for iLdd = 1:length(lddVec)
%         xLosNew(:,:,iLdd) = reshape(griddata(vec(RO1xLosTrue(:,:,iLdd)), vec(RO1yLosTrue(:,:,iLdd)), vec(xLos), vec(t0xLosTrue(:,:,iLdd)), vec(t0yLosTrue(:,:,iLdd))), nLos, nLos);
%         yLosNew(:,:,iLdd) = reshape(griddata(vec(RO1xLosTrue(:,:,iLdd)), vec(RO1yLosTrue(:,:,iLdd)), vec(yLos), vec(t0xLosTrue(:,:,iLdd)), vec(t0yLosTrue(:,:,iLdd))), nLos, nLos);
%     end
%     xLosAging = xLosNew-xLos;
%     yLosAging = yLosNew-yLos;
%     
%     figure(44+iUnit)
%     subplot(121), hold on
%     plot(lddVec, squeeze(xLosAging(midInd,1,:)), '-o')
%     plot(lddVec, squeeze(xLosAging(midInd,midInd,:)), '-o')
%     plot(lddVec, squeeze(xLosAging(midInd,nLos,:)), '-o')
%     grid on, xlabel('LDD [deg]'), ylabel('change [deg]'), legend(sprintf('x=%.1f[deg]',xLosVec(1)), sprintf('x=%.1f[deg]',xLosVec(midInd)), sprintf('x=%.1f[deg]',xLosVec(nLos))), title(sprintf('X change for y=%.1f[deg]', yLosVec(midInd)))
%     subplot(122), hold on
%     plot(lddVec, squeeze(yLosAging(1,midInd,:)), '-o')
%     plot(lddVec, squeeze(yLosAging(midInd,midInd,:)), '-o')
%     plot(lddVec, squeeze(yLosAging(nLos,midInd,:)), '-o')
%     grid on, xlabel('LDD [deg]'), ylabel('change [deg]'), legend(sprintf('y=%.1f[deg]',yLosVec(1)), sprintf('y=%.1f[deg]',yLosVec(midInd)), sprintf('y=%.1f[deg]',yLosVec(nLos))), title(sprintf('Y change for x=%.1f[deg]', xLosVec(midInd)))
%     sgtitle(sprintf('LOS aging for unit %s', t0.units{iUnit}))
%     
%     figure(48+iUnit)
%     subplot(121), hold on
%     plot(xLosVec, squeeze(xLosAging(1,:,midLddInd)), '-o')
%     plot(xLosVec, squeeze(xLosAging(midInd,:,midLddInd)), '-o')
%     plot(xLosVec, squeeze(xLosAging(nLos,:,midLddInd)), '-o')
%     grid on, xlabel('x [deg]'), ylabel('change [deg]'), legend(sprintf('y=%.1f[deg]',yLosVec(1)), sprintf('y=%.1f[deg]',yLosVec(midInd)), sprintf('y=%.1f[deg]',yLosVec(nLos))), title(sprintf('X change for T=%.1f[deg]', lddVec(midLddInd)))
%     subplot(122), hold on
%     plot(yLosVec, squeeze(yLosAging(:,1,midLddInd)), '-o')
%     plot(yLosVec, squeeze(yLosAging(:,midInd,midLddInd)), '-o')
%     plot(yLosVec, squeeze(yLosAging(:,nLos,midLddInd)), '-o')
%     grid on, xlabel('y [deg]'), ylabel('change [deg]'), legend(sprintf('x=%.1f[deg]',xLosVec(1)), sprintf('x=%.1f[deg]',xLosVec(midInd)), sprintf('x=%.1f[deg]',xLosVec(nLos))), title(sprintf('Y change for T=%.1f[deg]', lddVec(midLddInd)))
%     sgtitle(sprintf('LOS aging for unit %s', t0.units{iUnit}))
%     
%     figure(52+iUnit), hold on
%     quiver(vec(xLos), vec(yLos), vec(xLosAging(:,:,midLddInd)), vec(yLosAging(:,:,midLddInd)))
%     set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse')
%     grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('LOS aging for %s @ T=%.1f[deg]', t0.units{iUnit}, lddVec(midLddInd)))
%     
%     figure(56+iUnit), hold on
%     contour(xLosVec, yLosVec, sqrt(xLosAging(:,:,midLddInd).^2+yLosAging(:,:,midLddInd).^2));
%     set(gca, 'xdir', 'reverse'), set(gca, 'ydir', 'reverse'), colorbar
%     grid on, xlabel('x [deg]'), ylabel('y [deg]'), title(sprintf('LOS aging for %s @ T=%.1f[deg]', t0.units{iUnit}, lddVec(midLddInd)))
%     
%     fprintf('Done (%.1f sec)\n', toc(t));
% end

