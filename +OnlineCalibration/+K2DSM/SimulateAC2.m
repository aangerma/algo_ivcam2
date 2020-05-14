close all
clear all
clc

accPath = '\\143.185.124.250\tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3298\F0050036\ACC1';
atcPath = '\\143.185.124.250\tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3298\F0050036\ATC2';

%% fetching calibration data and unit state
regsDEST.hbaseline = 0;
regsDEST.baseline = -10;
regsDEST.baseline2 = regsDEST.baseline^2;

calData = Calibration.tables.getCalibDataFromCalPath(atcPath, accPath);
regs = calData.regs;
regs.DEST = mergestruct(regs.DEST, regsDEST);
tpsUndistModel = calData.tpsUndistModel;

acDataIn.hFactor = 1.002;
acDataIn.vFactor = 0.999;
acDataIn.hOffset = 0.053;
acDataIn.vOffset = 0.018;
acDataIn.flags = 1; % 1 - AOT model, 2 - TOA model
dsmRegs = Utils.convert.applyAcResOnDsmModel(acDataIn, regs.EXTL, 'direct');

%% mapping angles to pixels
sz = [768,1024];

tic
fprintf('Calculating intrinsic K...\n')
[~, origK] = Pipe.calcIntrinsicMat(regs, sz);
toc

tic
fprintf('Generating los-to-pixel mapping...\n');
[yPixGrid, xPixGrid] = ndgrid(0:sz(1)-1, 0:sz(2)-1);
vertices = [xPixGrid(:), yPixGrid(:), ones(prod(sz),1)] * inv(origK)';
rpt = Utils.convert.RptToVertices(vertices, regs, tpsUndistModel, 'inverse');
[losX, losY] = Utils.convert.applyDsm(rpt(:,2), rpt(:,3), regs.EXTL, 'inverse'); % original LOS during calibration
losX = double(losX);
losY = double(losY);
[agedLosX, agedLosY] = Utils.convert.applyDsm(rpt(:,2), rpt(:,3), dsmRegs, 'inverse'); % aged LOS leading to implicitly-generated special frame
xPixInterpolant = scatteredInterpolant(double(agedLosX), double(agedLosY), xPixGrid(:), 'linear'); % represents the implicitly-generated special frame
yPixInterpolant = scatteredInterpolant(double(agedLosX), double(agedLosY), yPixGrid(:), 'linear');
toc

%% point cloud randomization
isValidPix = false(size(xPixGrid));
nObj = 30;
objMaxRad = 30;
for iObj = 1:nObj
    objCenter = [sz(2)*rand, sz(1)*rand];
    objRad = objMaxRad*rand;
    isValidPix( (xPixGrid-objCenter(1)).^2+(yPixGrid-objCenter(2)).^2 <= objRad^2 ) = true;
end

figure
plot(xPixGrid(isValidPix), yPixGrid(isValidPix), '.')
grid on, title('Pixels participating in K optimization')
xlim([0, 200*ceil(sz(2)/200)]), ylim([0, 100*ceil(sz(1)/100)])

%% LOS error randomization
nRand = 10;
xScale = 0.98+0.04*rand(nRand,1);
xShift = -2+4*rand(nRand,1);
yScale = 0.98+0.04*rand(nRand,1);
yShift = -1+2*rand(nRand,1);
errPolyCoef = cat(3, [xScale, xShift], [yScale, yShift]);

%% simulating K optimization
tic
fprintf('Simulating AC2...\n')
optK = OnlineCalibration.K2DSM.OptimizeKUnderLosErrorSim(vertices(isValidPix,:), xPixInterpolant, yPixInterpolant, [losX(isValidPix), losY(isValidPix)], errPolyCoef);
modelFlag = 1; % 1 - AOT model, 2 - TOA model
toc

%% running alg
tic
fprintf('Running pre-processing...\n');
preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acDataIn, dsmRegs, sz, origK, isValidPix);
toc

tic
xLosScaling = zeros(nRand,1);
yLosScaling = zeros(nRand,1);
xLosShift = zeros(nRand,1);
yLosShift = zeros(nRand,1);
for iRand = 1:nRand
    fprintf('Running optimization for scenario #%d...\n', iRand);
    [losShift, losScaling] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, optK(:,:,iRand));
    acDataOut = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, modelFlag, losShift, losScaling);
    xLosScaling(iRand) = losScaling(1);
    yLosScaling(iRand) = losScaling(2);
    xLosShift(iRand) = losShift(1);
    yLosShift(iRand) = losShift(2);
end
toc

%% plotting
scalingLim = 0.002;
offsetLim = 0.1;

figure
subplot(221)
err = xLosScaling-xScale;
plot(xScale, err,'o')
grid on, ylim([min(-scalingLim, min(err)), max(scalingLim, max(err))]), xlabel('real scale factor'), ylabel('estimation error'), title('X scaling')
subplot(222)
err = yLosScaling-yScale;
plot(yScale, err,'o')
grid on, ylim([min(-scalingLim, min(err)), max(scalingLim, max(err))]), xlabel('real scale factor'), ylabel('estimation error'), title('Y scaling')
subplot(223)
err = xLosShift-xShift;
plot(xShift, err,'o')
grid on, ylim([min(-offsetLim, min(err)), max(offsetLim, max(err))]), xlabel('real shift'), ylabel('estimation error'), title('X shift')
subplot(224)
err = yLosShift-yShift;
plot(yShift, err,'o')
grid on, ylim([min(-offsetLim, min(err)), max(offsetLim, max(err))]), xlabel('real shift'), ylabel('estimation error'), title('Y shift')

mrkrs = {'o', 's', 'd', '^', 'p', 'o', 's', 'd', '^', 'p'};
clrs = [0,0,0.5;  0,0,1;  0,0.5,0;  0,1,0;  0.5,0,0;  1,0,0;  0.5,0,0.5;  1,0,1;  0,0.5,0.5;  0,1,1];
lgnd = {'optimal'};
for iRand = 1:nRand
    lgnd{iRand+1} = sprintf('#%d', iRand);
end

figure
subplot(221), hold on
plot(minmax(xScale), minmax(xScale), 'k-')
for iRand = 1:nRand
    plot(xScale(iRand), xLosScaling(iRand), mrkrs{iRand}, 'color', clrs(iRand,:), 'markerfacecolor', sqrt(clrs(iRand,:)))
end
grid on, xlabel('real scale factor'), ylabel('estimated scale factor'), title('Horizontal LOS scaling')
subplot(222), hold on
plot(minmax(yScale), minmax(yScale), 'k-')
for iRand = 1:nRand
    plot(yScale(iRand), yLosScaling(iRand), mrkrs{iRand}, 'color', clrs(iRand,:), 'markerfacecolor', sqrt(clrs(iRand,:)))
end
grid on, xlabel('real scale factor'), ylabel('estimated scale factor'), title('Vertical LOS scaling')
subplot(223), hold on
plot(minmax(xShift), minmax(xShift), 'k-')
for iRand = 1:nRand
    plot(xShift(iRand), xLosShift(iRand), mrkrs{iRand}, 'color', clrs(iRand,:), 'markerfacecolor', sqrt(clrs(iRand,:)))
end
grid on, xlabel('real shift'), ylabel('estimated shift'), title('Horizontal LOS shift')
subplot(224), hold on
plot(minmax(yShift), minmax(yShift), 'k-')
for iRand = 1:nRand
    plot(yShift(iRand), yLosShift(iRand), mrkrs{iRand}, 'color', clrs(iRand,:), 'markerfacecolor', sqrt(clrs(iRand,:)))
end
grid on, xlabel('real shift'), ylabel('estimated shift'), legend(lgnd), title('Vertical LOS shift')
sgtitle('K-based estimation of linear LOS error for different realizations')
