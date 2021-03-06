function [data] = applyThermalFix(data,regs,luts,calibParams,runParams,spherical)

framesData = data.framesData;
invalidFrames = arrayfun(@(j) isempty(framesData(j).ptsWithZ),1:numel(framesData));
framesData = framesData(~invalidFrames);

nBins = calibParams.fwTable.nRows;
N = nBins+1;
tempData = [framesData.temp];
vBias = reshape([framesData.vBias],3,[]);

table = data.tableResults.table;

newData = data;
framesData = data.framesData;
vBias = reshape([framesData.vBias],3,[]);
angleAdd = 2047;

%%
% Apply fix in Y
rowI = (vBias(2,:) - data.tableResults.angy.minval)/(data.tableResults.angy.maxval-data.tableResults.angy.minval);
rowI = 1+(nBins-1)*min(max(rowI,0),1);
dsmKeyY = [2,4];
[dsmValuesY] = calcDsmValues(dsmKeyY,rowI,table,nBins);
for k = 1:length(data.framesData)
    newData.framesData(k).ptsWithZ = data.framesData(k).ptsWithZ;
    aMemesY = (angleAdd + data.framesData(k).ptsWithZ(:,3))./regs.EXTL.dsmYscale-regs.EXTL.dsmYoffset;
    newAngY = (aMemesY+dsmValuesY(k,2)).*dsmValuesY(k,1)-angleAdd; % Apply the fix
    newData.framesData(k).ptsWithZ(:,3) = newAngY;
end

%%
% Apply the fix for x
% Handle X fix
deltaV1 = data.tableResults.angx.p1(1)-data.tableResults.angx.p0(1);
deltaV3 = data.tableResults.angx.p1(2)-data.tableResults.angx.p0(2);
dV1 = vBias(1,:) - data.tableResults.angx.p0(1);
dV3 = vBias(3,:) - data.tableResults.angx.p0(2);
rowI = (dV1*deltaV1+dV3*deltaV3)./(deltaV1^2 + deltaV3^2);
rowI = 1+(nBins-1)*min(max(rowI,0),1);

dsmKeyX = [1,3];
[dsmValuesX] = calcDsmValues(dsmKeyX,rowI,table,nBins);
for k = 1:length(data.framesData)
    aMemesX = (angleAdd + data.framesData(k).ptsWithZ(:,2))./regs.EXTL.dsmXscale-regs.EXTL.dsmXoffset;
    newAngX = (aMemesX+dsmValuesX(k,2)).*dsmValuesX(k,1)-angleAdd; % Apply the fix
    newData.framesData(k).ptsWithZ(:,2) = newAngX;
end

%%
% Fix RTD
lddTemp = [framesData.temp];
lddTemp = [lddTemp.ldd];
rowI = (lddTemp - calibParams.fwTable.tempBinRange(1))/(calibParams.fwTable.tempBinRange(2)-calibParams.fwTable.tempBinRange(1));
rowI = 1+(nBins-1)*min(max(rowI,0),1);
dsmKeyRtd = 5;
[dsmValuesRtd] = calcDsmValues(dsmKeyRtd,rowI,table,nBins);
for k = 1:length(data.framesData)
    newData.framesData(k).ptsWithZ(:,1) = newData.framesData(k).ptsWithZ(:,1) + dsmValuesRtd(k);
end
% Fix RTD Short
lddTempShort = [data.framesDataShort.temp];
lddTempShort = [lddTempShort.ldd];
rowI = (lddTempShort - calibParams.fwTable.tempBinRange(1))/(calibParams.fwTable.tempBinRange(2)-calibParams.fwTable.tempBinRange(1));
rowI = 1+(nBins-1)*min(max(rowI,0),1);
dsmKeyRtd = 5;
tmpTable = table;
tmpTable(:,5) = data.tableResults.rtd.tmptrOffsetValuesShort;
[dsmValuesRtd] = calcDsmValues(dsmKeyRtd,rowI,tmpTable,nBins);
for k = 1:length(data.framesDataShort)
    newData.framesDataShort(k).ptsWithZ(:,1) = newData.framesDataShort(k).ptsWithZ(:,1) + dsmValuesRtd(k);
end

%%
 % Calculate coordinates in image plane
inmin = -2074;
inmax = 2047;
for k = 1:length(data.framesData)
    if spherical
        
        invalid = isnan(newData.framesData(k).ptsWithZ(:,2));
        
        xx = (newData.framesData(k).ptsWithZ(:,2));
        yy = (newData.framesData(k).ptsWithZ(:,3));

        xx = xx*single(regs.DIGG.sphericalScale(1));
        yy = yy*single(regs.DIGG.sphericalScale(2));

        xx = (xx*2^(-12+2));
        yy = (yy*2^(-12));

        xx = xx+single(regs.DIGG.sphericalOffset(1));
        yy = yy+single(regs.DIGG.sphericalOffset(2));

        xx = max(-2^14,min(2^14-1,xx))/4;
        yy = max(-2^11,min(2^11-1,yy));

        xx(invalid) = nan;
        yy(invalid) = nan;
        newData.framesData(k).ptsWithZ(:,4:5) = [xx,yy] + 0.5; % The +0.5 is here so the center of the first pixel will be at 1 and not at 0.5
    else
        [newData.framesData(k).ptsWithZ(:,4),newData.framesData(k).ptsWithZ(:,5)] = ang2imageXy(newData.framesData(k).ptsWithZ(:,2),newData.framesData(k).ptsWithZ(:,3),regs,luts);
    end
end


% Apply fix to recorded min and max data
minMaxMemsAngX = reshape([data.framesData.minMaxMemsAngX],2,[])';
minMaxDSMAngX = (minMaxMemsAngX+dsmValuesX(:,2)).*dsmValuesX(:,1)-angleAdd; % Apply the fix

minMaxMemsAngY = reshape([data.framesData.minMaxMemsAngY],2,[])';
minMaxDSMAngY = (minMaxMemsAngY+dsmValuesY(:,2)).*dsmValuesY(:,1)-angleAdd; % Apply the fix

data.fixedData = newData;
data.dsmMovement.X = minMaxDSMAngX;
data.dsmMovement.Y = minMaxDSMAngY;
data.dsmMovement.minX = min(minMaxDSMAngX);
data.dsmMovement.maxX = max(minMaxDSMAngX);
data.dsmMovement.minY = min(minMaxDSMAngY);
data.dsmMovement.maxY = max(minMaxDSMAngY);

rangeRatio = max(diff(minMaxDSMAngY'))/min(diff(minMaxDSMAngY'));
data.tableResults.yDsmLosDegredation = 100*(abs(rangeRatio-1));

if calibParams.bananas.doExtrapolationInX
    lddGrid = (calibParams.bananas.extrapolationLddRange(1):calibParams.bananas.extrapolationLddRange(2))';

    sampleSize = calibParams.bananas.ransac.sampleSize; % number of points to sample per trial
    maxDistance = calibParams.bananas.ransac.maxDistance; % max allowable distance for inliers
    valueFunc = {@max; @(x) -min(x)};    
    for i = 1:2 
        points = [lddTemp(~isnan(minMaxDSMAngX(:,i)))',minMaxDSMAngX(~isnan(minMaxDSMAngX(:,i)),i)];
        res(i) = Calibration.thermal.biPolyRansac(points,calibParams.bananas.extrapolationPolyOrdersX(i),sampleSize,maxDistance,lddGrid,valueFunc{i});
        minMaxDSMAngXExtrap(:,i) = res(i).minMaxDSMAngExtrap;
    end
    
    data.dsmMovement.X = minMaxDSMAngXExtrap;
    data.dsmMovement.minX = min(minMaxDSMAngXExtrap);
    data.dsmMovement.maxX = max(minMaxDSMAngXExtrap);
    
    ff = Calibration.aux.invisibleFigure;
    subplot(121);
    plot(lddTemp,minMaxDSMAngX(:,1),'o');
    hold on
    plot(res(1).inlierPts(:,1), res(1).inlierPts(:,2),'g+')
    plot(lddGrid,minMaxDSMAngXExtrap(:,1),'-');
    xlabel('ldd[deg]');ylabel('DSM Units');title('extrapolation of lower DSM values');
    grid on
    subplot(122);
    plot(lddTemp,minMaxDSMAngX(:,2),'o');
    hold on
    plot(res(2).inlierPts(:,1), res(2).inlierPts(:,2),'g+')
    plot(lddGrid,minMaxDSMAngXExtrap(:,2),'-');
    xlabel('ldd[deg]');ylabel('DSM Units');title('extrapolation of upper DSM values');
    grid on
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('DSM_X_Extreme_Values'));

    
end
if calibParams.yFovDegredation.fitToPoly
    lddGrid = linspace(lddTemp(1),lddTemp(end),100)';
    sampleSize = calibParams.yFovDegredation.ransac.sampleSize; % number of points to sample per trial
    maxDistance = calibParams.yFovDegredation.ransac.maxDistance; % max allowable distance for inliers
    valueFunc = {@max; @(x) -min(x)};    
    for i = 1:2 
        points = [lddTemp(~isnan(minMaxDSMAngY(:,i)))',minMaxDSMAngY(~isnan(minMaxDSMAngY(:,i)),i)];
        res(i) = Calibration.thermal.biPolyRansac(points,calibParams.yFovDegredation.polyOrdersY(i),sampleSize,maxDistance,lddGrid,valueFunc{i});
        minMaxDSMAngYExtrap(:,i) = res(i).minMaxDSMAngExtrap;
    end
    
    
    data.dsmMovement.Y = minMaxDSMAngYExtrap;
    data.dsmMovement.minY = min(minMaxDSMAngYExtrap);
    data.dsmMovement.maxY = max(minMaxDSMAngYExtrap);
    rangeRatio = max(diff(minMaxDSMAngYExtrap'))/min(diff(minMaxDSMAngYExtrap'));
    data.tableResults.yDsmLosDegredation = 100*(abs(rangeRatio-1));
    
    ff = Calibration.aux.invisibleFigure;
    subplot(121);
    plot(lddTemp,minMaxDSMAngY(:,1),'o');
    hold on
    plot(res(1).inlierPts(:,1), res(1).inlierPts(:,2),'g+')
    plot(lddGrid,minMaxDSMAngYExtrap(:,1),'-');
    xlabel('ldd[deg]');ylabel('DSM Units');title('extrapolation of lower DSM values');
    grid on
    subplot(122);
    plot(lddTemp,minMaxDSMAngY(:,2),'o');
    hold on
    plot(res(2).inlierPts(:,1), res(2).inlierPts(:,2),'g+')
    plot(lddGrid,minMaxDSMAngYExtrap(:,2),'-');
    xlabel('ldd[deg]');ylabel('DSM Units');title('extrapolation of upper DSM values');
    grid on
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('DSM_Y_Extreme_Values'));

    
end
end

%%
function [dsmValues] = calcDsmValues(dsmKey,rowI,table,nBins)
dsmValues = zeros(numel(rowI),length(dsmKey));
dsmValues(rowI == 1,:) = ones(size(dsmValues(rowI == 1,:))) .* table(1,dsmKey);
dsmValues(rowI == (nBins),:) = ones(size(dsmValues(rowI == (nBins),:))) .* table(end,dsmKey);
innerIndices = ~((rowI == 1) | rowI == nBins);
innerRows = rowI(innerIndices)';
innerRowsLow = floor(innerRows);
innerRowsFraq = innerRows - floor(innerRows);

newValues = innerRowsFraq.* table(innerRowsLow+1,dsmKey) + (1-innerRowsFraq).* table(innerRowsLow,dsmKey);
dsmValues(innerIndices',:) = newValues;
end

function [x,y] = ang2imageXy(angX,angY,regs,luts)
ixNan = isnan(angX);
[x_,y_] = Pipe.DIGG.ang2xy(angX,angY,regs,[],[]);
[x,y] = Pipe.DIGG.undist(x_,y_,regs,luts,[],[]);
x = single(x)/2^15;
y = single(y)/2^15;
x(ixNan) = nan;
y(ixNan) = nan;
end
