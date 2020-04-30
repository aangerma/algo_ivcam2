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
    [origPixY, origPixX] = ndgrid(y, x);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, origPixX(:), origPixY(:), polyCoef);
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
Kopt = zeros(3,3,length(yScale),length(roiVals));
for iRoi = 1:length(roiVals)
    roi = [1, 1]*roiVals(iRoi); % [y, x]
    margin = (1-roi)/2.*sz;
    x = 1+margin(2):dPix:sz(2)-margin(2);
    y = 1+margin(1):dPix:sz(1)-margin(1);
    [origPixY, origPixX] = ndgrid(y, x);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, origPixX(:), origPixY(:), polyCoef);
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
    [origPixY, origPixX] = ndgrid(y, x);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, origPixX(:), origPixY(:), polyCoef);
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
    [origPixY, origPixX] = ndgrid(y, x);
    lgnd{iRoi} = sprintf('%d%%X%d%% ROI', round(100*roi(1)), round(100*roi(2)));
    Kopt(:,:,:,iRoi) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, origPixX(:), origPixY(:), polyCoef);
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
    [origPixY, origPixX] = ndgrid(y, x);
    plot(origPixX(:), origPixY(:), '.')
    Kopt(:,:,iMargin) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, origPixX(:), origPixY(:), polyCoef);
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
    [origPixY, origPixX] = ndgrid(y, x);
    plot(origPixX(:), origPixY(:), '.')
    Kopt(:,:,iMargin) = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, origPixX(:), origPixY(:), polyCoef);
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

%% scaling ratios ma
sc = 1.025;

temp = out;
temp.angx = sc*temp.angx;
temp2 = Utils.convert.SphericalToCartesian(temp, regs, 'direct');
temp2.vertices = temp2.vertices./temp2.vertices(:,3);
ratio = (temp2.vertices./in.vertices - 1) / (sc-1);

Kxx = reshape(ratio(:,1),sz);
lims = prctile(Kxx(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Kxx = max(lims(1), min(lims(2), Kxx));
KxxTemp = medfilt2(Kxx,[5,5]);
Kxx(:,3:end-2) = KxxTemp(:,3:end-2);

Kyx = reshape(ratio(:,2),sz);
lims = prctile(Kyx(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Kyx = max(lims(1), min(lims(2), Kyx));
KyxTemp = medfilt2(Kyx,[5,5]);
Kyx(3:end-2,:) = KyxTemp(3:end-2,:);

temp = out;
temp.angy = sc*temp.angy;
temp2 = Utils.convert.SphericalToCartesian(temp, regs, 'direct');
temp2.vertices = temp2.vertices./temp2.vertices(:,3);
ratio = (temp2.vertices./in.vertices - 1) / (sc-1);

Kxy = reshape(ratio(:,1),sz);
lims = prctile(Kxy(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Kxy = max(lims(1), min(lims(2), Kxy));
KxyTemp = medfilt2(Kxy,[5,5]);
Kxy(:,3:end-2) = KxyTemp(:,3:end-2);

Kyy = reshape(ratio(:,2),sz);
lims = prctile(Kyy(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Kyy = max(lims(1), min(lims(2), Kyy));
KyyTemp = medfilt2(Kyy,[5,5]);
Kyy(3:end-2,:) = KyyTemp(3:end-2,:);

figure
subplot(221), imagesc(Kxx), title('Fx/LOSx scaling ratio'), colorbar
subplot(222), imagesc(Kyx), title('Fy/LOSx scaling ratio'), colorbar
subplot(223), imagesc(Kxy), title('Fx/LOSy scaling ratio'), colorbar
subplot(224), imagesc(Kyy), title('Fy/LOSy scaling ratio'), colorbar

%% scaling ratios ma
of = 1;

temp = out;
temp.angx = temp.angx+of;
temp2 = Utils.convert.SphericalToCartesian(temp, regs, 'direct');
temp2.vertices = temp2.vertices./temp2.vertices(:,3);
ratio = [origK(1,1), origK(2,2), 1].*(temp2.vertices-in.vertices) / of;

Lxx = reshape(ratio(:,1),sz);
lims = prctile(Lxx(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Lxx = max(lims(1), min(lims(2), Lxx));
LxxTemp = medfilt2(Lxx,[5,5]);
Lxx(:,3:end-2) = LxxTemp(:,3:end-2);

Lyx = reshape(ratio(:,2),sz);
lims = prctile(Lyx(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Lyx = max(lims(1), min(lims(2), Lyx));
LyxTemp = medfilt2(Lyx,[5,5]);
Lyx(3:end-2,:) = LyxTemp(3:end-2,:);

temp = out;
temp.angy = temp.angy+of;
temp2 = Utils.convert.SphericalToCartesian(temp, regs, 'direct');
temp2.vertices = temp2.vertices./temp2.vertices(:,3);
ratio = [origK(1,1), origK(2,2), 1].*(temp2.vertices-in.vertices) / of;

Lxy = reshape(ratio(:,1),sz);
lims = prctile(Lxy(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Lxy = max(lims(1), min(lims(2), Lxy));
LxyTemp = medfilt2(Lxy,[5,5]);
Lxy(:,3:end-2) = LxyTemp(:,3:end-2);

Lyy = reshape(ratio(:,2),sz);
lims = prctile(Lyy(:),[5,95]);
lims = lims+[-1,1]*diff(lims);
Lyy = max(lims(1), min(lims(2), Lyy));
LyyTemp = medfilt2(Lyy,[5,5]);
Lyy(3:end-2,:) = LyyTemp(3:end-2,:);

figure
subplot(221), imagesc(Lxx), title('Px/LOSx shift ratio'), colorbar
subplot(222), imagesc(Lyx), title('Py/LOSx shift ratio'), colorbar
subplot(223), imagesc(Lxy), title('Px/LOSy shift ratio'), colorbar
subplot(224), imagesc(Lyy), title('Py/LOSy shift ratio'), colorbar

%% combined effect of linear LOS error - point cloud generation
isValidPix = false(size(xx));
nObj = 30;
objMaxRad = 30;
for iObj = 1:nObj
    center = [sz(2)*rand, sz(1)*rand];
    objRad = objMaxRad*rand;
    isValidPix((xx-center(1)).^2+(yy-center(2)).^2<=objRad^2) = true;
end
figure
plot(xx(isValidPix), yy(isValidPix), '.')
grid on, title('Pixels participating in K optimization')

%% combined effect of linear LOS error - single realization testing
xScale = 1.005;
xOffset = 2.4;
yScale = 0.985;
yOffset = -0.77;
polyCoef = cat(3, [xScale, xOffset], [yScale, yOffset]);
Kopt = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, xx(isValidPix), yy(isValidPix), polyCoef);
fxScaling = Kopt(1,1)/origK(1,1);
fyScaling = Kopt(2,2)/origK(2,2);
pxShift = Kopt(1,3)-origK(1,3);
pyShift = Kopt(2,3)-origK(2,3);
scalingRatioMat = [mean(Kxx(isValidPix)), mean(Kxy(isValidPix)); mean(Kyx(isValidPix)), mean(Kyy(isValidPix))];
shiftRatioMat = [mean(Lxx(isValidPix)), mean(Lxy(isValidPix)); mean(Lyx(isValidPix)), mean(Lyy(isValidPix))];
[xLosScaling, yLosScaling] = CalcUnderlyingLosScaling(scalingRatioMat, fxScaling, fyScaling);
temp = shiftRatioMat\[pxShift; pyShift];
xLosShift = temp(1);
yLosShift = temp(2);

%% combined effect of linear LOS error - multiple realizations testing
nReal = 10;
xScale = 0.98+0.04*rand(nReal,1);
xOffset = -2+4*rand(nReal,1);
yScale = 0.98+0.04*rand(nReal,1);
yOffset = -1+2*rand(nReal,1);
polyCoef = cat(3, [xScale, xOffset], [yScale, yOffset]);
Kopt = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, xx(isValidPix), yy(isValidPix), polyCoef);
fxScaling = squeeze(Kopt(1,1,:))/origK(1,1);
fyScaling = squeeze(Kopt(2,2,:))/origK(2,2);
pxShift = squeeze(Kopt(1,3,:))-origK(1,3);
pyShift = squeeze(Kopt(2,3,:))-origK(2,3);
scalingRatioMat = [mean(Kxx(isValidPix)), mean(Kxy(isValidPix)); mean(Kyx(isValidPix)), mean(Kyy(isValidPix))];
shiftRatioMat = [mean(Lxx(isValidPix)), mean(Lxy(isValidPix)); mean(Lyx(isValidPix)), mean(Lyy(isValidPix))];
xLosScaling = zeros(1,nReal);
yLosScaling = zeros(1,nReal);
xLosShift = zeros(1,nReal);
yLosShift = zeros(1,nReal);
for iReal = 1:nReal
    [xLosScaling(iReal), yLosScaling(iReal)] = CalcUnderlyingLosScaling(scalingRatioMat, fxScaling(iReal), fyScaling(iReal));
    temp = shiftRatioMat\[pxShift(iReal); pyShift(iReal)];
    xLosShift(iReal) = temp(1);
    yLosShift(iReal) = temp(2);
end

mrkrs = {'o', 's', 'd', '^', 'p', 'o', 's', 'd', '^', 'p'};
clrs = [0,0,0.5;  0,0,1;  0,0.5,0;  0,1,0;  0.5,0,0;  1,0,0;  0.5,0,0.5;  1,0,1;  0,0.5,0.5;  0,1,1];
lgnd = {'optimal'};
for iReal = 1:nReal
    lgnd{iReal+1} = sprintf('#%d', iReal);
end

figure
subplot(221), hold on
plot(minmax(xScale), minmax(xScale), 'k-')
for iReal = 1:nReal
    plot(xScale(iReal), xLosScaling(iReal), mrkrs{iReal}, 'color', clrs(iReal,:), 'markerfacecolor', sqrt(clrs(iReal,:)))
end
grid on, xlabel('real scale factor'), ylabel('estimated scale factor'), title('Horizontal LOS scaling')
subplot(222), hold on
plot(minmax(yScale), minmax(yScale), 'k-')
for iReal = 1:nReal
    plot(yScale(iReal), yLosScaling(iReal), mrkrs{iReal}, 'color', clrs(iReal,:), 'markerfacecolor', sqrt(clrs(iReal,:)))
end
grid on, xlabel('real scale factor'), ylabel('estimated scale factor'), title('Vertical LOS scaling')
subplot(223), hold on
plot(minmax(xOffset), minmax(xOffset), 'k-')
for iReal = 1:nReal
    plot(xOffset(iReal), xLosShift(iReal), mrkrs{iReal}, 'color', clrs(iReal,:), 'markerfacecolor', sqrt(clrs(iReal,:)))
end
grid on, xlabel('real shift'), ylabel('estimated shift'), title('Horizontal LOS shift')
subplot(224), hold on
plot(minmax(yOffset), minmax(yOffset), 'k-')
for iReal = 1:nReal
    plot(yOffset(iReal), yLosShift(iReal), mrkrs{iReal}, 'color', clrs(iReal,:), 'markerfacecolor', sqrt(clrs(iReal,:)))
end
grid on, xlabel('real shift'), ylabel('estimated shift'), legend(lgnd), title('Vertical LOS shift')
sgtitle('K-based estimation of linear LOS error for different realizations')
