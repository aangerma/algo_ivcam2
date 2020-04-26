close all
clear all
clc

%% regs definition
regs.FRMW.laserangleH = 0;
regs.FRMW.laserangleV = 0;

regs.FRMW.fovexExistenceFlag = 1;
regs.FRMW.fovexNominal = [0.0807405, 0.0030212, -0.0001276, 0.0000036];
regs.FRMW.fovexCenter = [0, 0];
regs.FRMW.fovexLensDistFlag = 0;
regs.FRMW.fovexRadialK = [0, 0, 0];
regs.FRMW.fovexTangentP = [0 0];

regs.DEST.baseline = -10;
regs.DEST.baseline2 = regs.DEST.baseline^2;

%% mapping angles to pixels
sz = [768,1024];
origK = [1024/2/tand(35), 0, 1024/2; 0, 768/2/tand(27), 768/2; 0, 0, 1]; % an "ideal" intrinsic matrix for XGA

[yy, xx] = ndgrid(1:sz(1), 1:sz(2));
in.vertices = [xx(:), yy(:), ones(prod(sz),1)] * inv(origK)';
tic
fprintf('Generating angles2pixels mapping...\n');
out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
xPixInterpolant = scatteredInterpolant(double(out.angx), double(out.angy), xx(:), 'linear');
yPixInterpolant = scatteredInterpolant(double(out.angx), double(out.angy), yy(:), 'linear');
toc

%% effect of X scaling
dPix = 20;
roiVals = [1, 0.75, 0.5, 0.25];
xScale = (0.95:0.01:1.05)';
polyCoef = cat(3, [xScale, zeros(length(xScale),1)], ones(length(xScale),1)*[1,0]);
Kopt = zeros(3,3,length(xScale),length(roiVals));
for iRoi = 1:length(roiVals)
    roi = [1, 1]*roiVals(iRoi); % [y, x]
    margin = (1-roi)/2.*sz;
    x = 1+margin(2):dPix:sz(2)-margin(2);
    y = 1+margin(1):dPix:sz(1)-margin(1);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, x, y, polyCoef);
end
fx = squeeze(Kopt(1,1,:,:));
fy = squeeze(Kopt(2,2,:,:));
px = squeeze(Kopt(1,3,:,:));
py = squeeze(Kopt(2,3,:,:));
styles = {'-', '--', '-.', ':'};
figure, hold on
for iRoi = 1:length(roiVals)
    plot(xScale, fx(:,iRoi)/origK(1,1), 'b', 'linestyle', styles{iRoi})
end
for iRoi = 1:length(roiVals)
    plot(xScale, fy(:,iRoi)/origK(2,2), 'r', 'linestyle', styles{iRoi})
end
grid on, xlabel('LOS X scaling factor'), ylabel('K scaling factor'), legend(lgnd), title('Effect of LOS X scaling on Fx (blue) and Fy (red)')

%% effect of Y scaling
dPix = 20;
roiVals = [1, 0.75, 0.5, 0.25];
yScale = (0.95:0.01:1.05)';
polyCoef = cat(3, ones(length(yScale),1)*[1,0], [yScale, zeros(length(yScale),1)]);
Kopt = zeros(3,3,length(xScale),length(roiVals));
for iRoi = 1:length(roiVals)
    roi = [1, 1]*roiVals(iRoi); % [y, x]
    margin = (1-roi)/2.*sz;
    x = 1+margin(2):dPix:sz(2)-margin(2);
    y = 1+margin(1):dPix:sz(1)-margin(1);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, x, y, polyCoef);
end
fx = squeeze(Kopt(1,1,:,:));
fy = squeeze(Kopt(2,2,:,:));
px = squeeze(Kopt(1,3,:,:));
py = squeeze(Kopt(2,3,:,:));
styles = {'-', '--', '-.', ':'};
figure, hold on
for iRoi = 1:length(roiVals)
    plot(yScale, fx(:,iRoi)/origK(1,1), 'b', 'linestyle', styles{iRoi})
end
for iRoi = 1:length(roiVals)
    plot(yScale, fy(:,iRoi)/origK(2,2), 'r', 'linestyle', styles{iRoi})
end
grid on, xlabel('LOS Y scaling factor'), ylabel('K scaling factor'), legend(lgnd), title('Effect of LOS Y scaling on Fx (blue) and Fy (red)')

%% effect of X shift
dPix = 20;
roiVals = [1, 0.75, 0.5, 0.25];
xShift = (-1:0.1:1)';
polyCoef = cat(3, [ones(length(xShift),1), xShift], ones(length(xShift),1)*[1,0]);
Kopt = zeros(3,3,length(xShift),length(roiVals));
for iRoi = 1:length(roiVals)
    roi = [1, 1]*roiVals(iRoi); % [y, x]
    margin = (1-roi)/2.*sz;
    x = 1+margin(2):dPix:sz(2)-margin(2);
    y = 1+margin(1):dPix:sz(1)-margin(1);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, x, y, polyCoef);
end
fx = squeeze(Kopt(1,1,:,:));
fy = squeeze(Kopt(2,2,:,:));
px = squeeze(Kopt(1,3,:,:));
py = squeeze(Kopt(2,3,:,:));
styles = {'-', '--', '-.', ':'};
figure, hold on
for iRoi = 1:length(roiVals)
    plot(xShift, px(:,iRoi)-origK(1,3), 'b', 'linestyle', styles{iRoi})
end
for iRoi = 1:length(roiVals)
    plot(xShift, py(:,iRoi)-origK(2,3), 'r', 'linestyle', styles{iRoi})
end
grid on, xlabel('LOS X shift [\circ]'), ylabel('K principle point shift'), legend(lgnd), title('Effect of LOS X shift on Px (blue) and Py (red)')

%% effect of Y shift
dPix = 20;
roiVals = [1, 0.75, 0.5, 0.25];
yShift = (-1:0.1:1)';
polyCoef = cat(3, ones(length(yShift),1)*[1,0], [ones(length(yShift),1), yShift]);
Kopt = zeros(3,3,length(yShift),length(roiVals));
for iRoi = 1:length(roiVals)
    roi = [1, 1]*roiVals(iRoi); % [y, x]
    margin = (1-roi)/2.*sz;
    x = 1+margin(2):dPix:sz(2)-margin(2);
    y = 1+margin(1):dPix:sz(1)-margin(1);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, x, y, polyCoef);
end
fx = squeeze(Kopt(1,1,:,:));
fy = squeeze(Kopt(2,2,:,:));
px = squeeze(Kopt(1,3,:,:));
py = squeeze(Kopt(2,3,:,:));
styles = {'-', '--', '-.', ':'};
figure, hold on
for iRoi = 1:length(roiVals)
    plot(yShift, px(:,iRoi)-origK(1,3), 'b', 'linestyle', styles{iRoi})
end
for iRoi = 1:length(roiVals)
    plot(yShift, py(:,iRoi)-origK(2,3), 'r', 'linestyle', styles{iRoi})
end
grid on, xlabel('LOS Y shift [\circ]'), ylabel('K principle point shift'), legend(lgnd), title('Effect of LOS Y shift on Px (blue) and Py (red)')

%% effect of X scaling for dynamic ROI
dPix = 20;
% margins = [0.25, 0.25, 0.25, 0.25; 0.375, 0.25, 0.125, 0.25; 0.5, 0.25, 0, 0.25; 0.5, 0.375, 0, 0.125; 0.5, 0.5, 0, 0]; roiSizeStr = '50%X50%'; % x-left, y-top, x-right, y-bottom
margins = [0.375, 0.375, 0.375, 0.375; 0.5625, 0.375, 0.1875, 0.375; 0.75, 0.375, 0, 0.375; 0.75, 0.5625, 0, 0.1875; 0.75, 0.75, 0, 0]; roiSizeStr = '25%X25%'; % x-left, y-top, x-right, y-bottom
xScale = 1.05;
polyCoef = cat(3, [xScale, 0], [1, 0]);
Kopt = zeros(3,3,size(margins,1));
figure
subplot(121), hold on
for iMargin = 1:size(margins,1)
    margin = margins(iMargin,:).*[sz(2), sz(1), sz(2), sz(1)];
    x = 1+margin(1):dPix:sz(2)-margin(3);
    y = 1+margin(2):dPix:sz(1)-margin(4);
    [yy,xx] = ndgrid(y,x);
    plot(xx(:), yy(:), '.')
    Kopt(:,:,iMargin) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, x, y, polyCoef);
end
grid on, xlabel('x'), ylabel('y'), title(sprintf('Possible choices for %s ROI', roiSizeStr)), set(gca,'ydir','reverse'), xlim([0 1025]), ylim([0 769])
fx = squeeze(Kopt(1,1,:));
fy = squeeze(Kopt(2,2,:));
px = squeeze(Kopt(1,3,:));
py = squeeze(Kopt(2,3,:));
subplot(122), hold on
for iMargin = 1:size(margins,1)
    h = plot(fx(iMargin)/origK(1,1)/xScale, fy(iMargin)/origK(2,2)/xScale, 'o');
    set(h, 'markerfacecolor', sqrt(get(h,'color')))
end
grid on, xlabel('Fx/LOSx scaling ratio'), ylabel('Fy/LOSx scaling ratio'), title('Effect of LOS X scaling on K scaling')

%% effect of X shift for dynamic ROI
dPix = 20;
% margins = [0.25, 0.25, 0.25, 0.25; 0.375, 0.25, 0.125, 0.25; 0.5, 0.25, 0, 0.25; 0.5, 0.375, 0, 0.125; 0.5, 0.5, 0, 0]; roiSizeStr = '50%X50%'; % x-left, y-top, x-right, y-bottom
margins = [0.375, 0.375, 0.375, 0.375; 0.5625, 0.375, 0.1875, 0.375; 0.75, 0.375, 0, 0.375; 0.75, 0.5625, 0, 0.1875; 0.75, 0.75, 0, 0]; roiSizeStr = '25%X25%'; % x-left, y-top, x-right, y-bottom
xShift = 1;
polyCoef = cat(3, [1, xShift], [1, 0]);
Kopt = zeros(3,3,size(margins,1));
figure
subplot(121), hold on
for iMargin = 1:size(margins,1)
    margin = margins(iMargin,:).*[sz(2), sz(1), sz(2), sz(1)];
    x = 1+margin(1):dPix:sz(2)-margin(3);
    y = 1+margin(2):dPix:sz(1)-margin(4);
    [yy,xx] = ndgrid(y,x);
    plot(xx(:), yy(:), '.')
    Kopt(:,:,iMargin) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, x, y, polyCoef);
end
grid on, xlabel('x'), ylabel('y'), title(sprintf('Possible choices for %s ROI', roiSizeStr)), set(gca,'ydir','reverse'), xlim([0 1025]), ylim([0 769])
fx = squeeze(Kopt(1,1,:));
fy = squeeze(Kopt(2,2,:));
px = squeeze(Kopt(1,3,:));
py = squeeze(Kopt(2,3,:));
subplot(122), hold on
for iMargin = 1:size(margins,1)
    h = plot((px(iMargin)-origK(1,3))/xShift, (py(iMargin)/origK(2,3))/xShift, 'o');
    set(h, 'markerfacecolor', sqrt(get(h,'color')))
end
grid on, xlabel('Px/LOSx shift ratio'), ylabel('Py/LOSx shift ratio'), title('Effect of LOS X shift on principle point')


