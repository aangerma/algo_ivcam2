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
% acDataIn.hFactor = 1.000;
% acDataIn.vFactor = 1.000;
acDataIn.hOffset = 0.000;
acDataIn.vOffset = 0.000;
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
xShift = zeros(nRand,1);
yScale = 0.98+0.04*rand(nRand,1);
yShift = zeros(nRand,1);
errPolyCoef = cat(3, [xScale, xShift], [yScale, yShift]);

%% simulating K optimization
tic
fprintf('Simulating AC2...\n')
% optK = OnlineCalibration.K2DSM.OptimizeKUnderLosErrorSim(origK, vertices(isValidPix,:), xPixInterpolant, yPixInterpolant, [losX(isValidPix), losY(isValidPix)], errPolyCoef);
optK = OnlineCalibration.K2DSM.OptimizeKUnderLosErrorSim2(origK, vertices, xPixInterpolant, yPixInterpolant, [losX, losY], errPolyCoef, isValidPix);
modelFlag = 1; % 1 - AOT model, 2 - TOA model
maxLosScalingStep = 0.02;
toc

%% running alg
tic
fprintf('Running pre-processing...\n');
preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acDataIn, dsmRegs, origK, isValidPix, maxLosScalingStep);
toc

tic
xLosScaling = zeros(nRand,1);
yLosScaling = zeros(nRand,1);
for iRand = 1:nRand
    fprintf('Running optimization for scenario #%d...\n', iRand);
    losScaling = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, optK(:,:,iRand));
    acDataOut = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, modelFlag, zeros(2,1), losScaling);
    xLosScaling(iRand) = losScaling(1);
    yLosScaling(iRand) = losScaling(2);
end
toc

%% plotting
figure
subplot(121)
cdfplot(xLosScaling-xScale)
grid on, xlabel('scale factor error'), ylabel('CDF'), title('X scaling')
subplot(122)
cdfplot(yLosScaling-yScale);
grid on, xlabel('scale factor error'), ylabel('CDF'), title('Y scaling')

if (nRand==10)
    scalingLim = 0.002;
    
    figure
    subplot(221)
    err = xLosScaling-xScale;
    plot(xScale, err,'o')
    grid on, ylim([min(-scalingLim, min(err)), max(scalingLim, max(err))]), xlabel('real scale factor'), ylabel('estimation error'), title('X scaling')
    subplot(222)
    err = yLosScaling-yScale;
    plot(yScale, err,'o')
    grid on, ylim([min(-scalingLim, min(err)), max(scalingLim, max(err))]), xlabel('real scale factor'), ylabel('estimation error'), title('Y scaling')
    
    mrkrs = {'o', 's', 'd', '^', 'p', 'o', 's', 'd', '^', 'p'};
    clrs = [0,0,0.5;  0,0,1;  0,0.5,0;  0,1,0;  0.5,0,0;  1,0,0;  0.5,0,0.5;  1,0,1;  0,0.5,0.5;  0,1,1];
    lgnd = {'optimal'};
    for iRand = 1:nRand
        lgnd{iRand+1} = sprintf('#%d', iRand);
    end
    
    subplot(223), hold on
    plot(minmax(xScale), minmax(xScale), 'k-')
    for iRand = 1:nRand
        plot(xScale(iRand), xLosScaling(iRand), mrkrs{iRand}, 'color', clrs(iRand,:), 'markerfacecolor', sqrt(clrs(iRand,:)))
    end
    grid on, xlabel('real scale factor'), ylabel('estimated scale factor'), title('Horizontal LOS scaling')
    subplot(224), hold on
    plot(minmax(yScale), minmax(yScale), 'k-')
    for iRand = 1:nRand
        plot(yScale(iRand), yLosScaling(iRand), mrkrs{iRand}, 'color', clrs(iRand,:), 'markerfacecolor', sqrt(clrs(iRand,:)))
    end
    grid on, xlabel('real scale factor'), ylabel('estimated scale factor'), title('Vertical LOS scaling')
    sgtitle('K-based estimation of LOS scaling error for different realizations')
end

%% Point cloud errors
err = zeros(0,3);
for iRand = 1:nRand
    fprintf('Post processing scenario #%d...\n', iRand);
    optAcData = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, modelFlag, zeros(2,1), [xLosScaling(iRand); yLosScaling(iRand)]);
%     optAcData = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, modelFlag, zeros(2,1), [xScale(iRand); yScale(iRand)]);
    optDsmRegs.dsmXscale = regs.EXTL.dsmXscale*optAcData.hFactor;
    optDsmRegs.dsmYscale = regs.EXTL.dsmYscale*optAcData.vFactor;
    optDsmRegs.dsmXoffset = (regs.EXTL.dsmXoffset+optAcData.hOffset)/optAcData.hFactor;
    optDsmRegs.dsmYoffset = (regs.EXTL.dsmYoffset+optAcData.vOffset)/optAcData.vFactor;
    
    finalLosX = xScale(iRand)*losX(isValidPix(:));
    finalLosY = yScale(iRand)*losY(isValidPix(:));
    [finalDsmX, finalDsmY] = Utils.convert.applyDsm(finalLosX, finalLosY, optDsmRegs, 'direct');
    finalVertices = Utils.convert.RptToVertices([0*finalDsmX+6000, finalDsmX, finalDsmY], regs, tpsUndistModel, 'direct');
    finalVertices = finalVertices./finalVertices(:,3);
    optVertices = [xPixGrid(isValidPix(:)), yPixGrid(isValidPix(:)), ones(sum(isValidPix(:)),1)] * inv(origK)';
    err = [err; finalVertices-optVertices];
end

% figure, hold on, for k=1:2, plot(err(:,k)), end, grid on, legend('x','y')
% figure, plot(finalVertices(:,1), finalVertices(:,2),'.'), grid on, hold on, plot(optVertices(:,1), optVertices(:,2),'.')
figure
hold on
for k = 1:2
    cdfplot(1000*err(:,k))
end
grid on, xlabel('vertices error [mm] @ depth 1000mm'), legend('x','y')

