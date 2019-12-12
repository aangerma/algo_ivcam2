function [table, results] = generateFWTable(data, calibParams, runParams, fprintff)
% Bin frames according to fw loop requirment.
% Generate a linear fix for angles and an offset for rtd

% •	All values are fixed point 8.8
% •	Range is [32,79] degrees – row for every 1 degree of Ldd for
% temperature offset fix
% •	Linear interpolation
% •	Averaging of 10 last LDD temperature measurements every second. Temperature sample rate is 10Hz. Same for vBias and Ibias 
% •	Replace “Reserved_512_Calibration_1_CalibData_Ver_20_00.txt” with ~“Algo_Thermal_Loop_512_ 1_CalibInfo_Ver_21_00.bin” 
% •	In case table does not exist, continue working with old thermal loop

framesData = data.framesData;
timeVec = [framesData.time];


regs = data.regs;

nBins = calibParams.fwTable.nRows;
N = nBins+1;
tempData = [framesData.temp];
vBias = reshape([framesData.vBias],3,[]);
ldd = [tempData.ldd];
timev = [framesData.time];

validPerFrame = arrayfun(@(x) ~isnan(x.ptsWithZ(:,1)),framesData,'UniformOutput',false)';
validPerFrame = cell2mat(validPerFrame);
validCB = all(validPerFrame,2);


%% Temperatures management
ma = [tempData.ma];
tsense = [tempData.tsense];
shtw2 = [tempData.shtw2];
[~,indMinDif] = min(shtw2-tsense);
try
    fitIdcs = abs(shtw2-shtw2(indMinDif))<10;
    p = polyfit(shtw2(fitIdcs), shtw2(fitIdcs)-tsense(fitIdcs), 2);
    humidMinDif = -p(2)/(2*p(1));
    results.temp.FRMWhumidApdTempDiff = p(1)*humidMinDif.^2 + p(2)*humidMinDif + p(3); % denoised minimum
catch
    fprintf('WARNING: shtw2-tsense estimation failed, resorting to minimal difference.\n');
    results.temp.FRMWhumidApdTempDiff = shtw2(indMinDif)-tsense(indMinDif); % simple minimum
end
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(ldd, '.-')
    plot(ma, '.-')
    plot(tsense, '.-')
    plot(shtw2, '.-')
    [~,ind] = min(abs(shtw2-humidMinDif));
    plot([ind,ind], [tsense(ind),shtw2(ind)], '.-')
    leg = {'LDD', 'MA', 'TSense', 'SHTW2', 'humidApdTempDiff'};
    text(ind, mean([tsense(ind),shtw2(ind)]), sprintf('%.2f', results.temp.FRMWhumidApdTempDiff))
    grid on, xlabel('#frame'), ylabel('temperature [deg]')
    legend(leg,'Location','northwest')
    title('Temperature readings')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('TemperatureReadings'));
end
if calibParams.warmUp.checkTmptrSensors && ~checkTemperaturesValidity(ldd, ma, tsense, shtw2, fprintff)
    results = [];
    table = [];
    return;
end

%% IR statistics
if isfield(framesData, 'irStat')
    irData = [framesData.irStat];
    irMean = [irData.mean];
    irStd = [irData.std];
    irNumPix = [irData.nPix];
    if ~isempty(runParams)
        ff = Calibration.aux.invisibleFigure;
        hold on
        plot(ldd, irMean, 'b')
        plot(ldd, irMean+irStd, 'r--')
        plot(ldd, irMean-irStd, 'r--')
        title(sprintf('IR in central white tiles (%.1f+-%.1f pixels)', mean(irNumPix), std(irNumPix)));
        grid on; xlabel('LDD [deg]'); ylabel('IR');
        legend('mean', 'STD margin')
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('IR_statistics'));
    end
end

%% RTD fix
rtdPerFrame = arrayfun(@(x) nanmean(x.ptsWithZ(validCB,1)),framesData);

% legacy
startI = calibParams.fwTable.nFramesToIgnore+1;
verifyThermalSweepValidity(ldd, startI, calibParams.warmUp)
[aMA,bMA] = linearTrans(vec(ma(startI:end)),vec(rtdPerFrame(startI:end)));
results.ma.slope = aMA;

% jump detection
jumpIdcs = detectJump(rtdPerFrame, 'RTD', calibParams.fwTable.jumpDet, true, runParams);
if isempty(jumpIdcs) % no jump detected
    ind = 1;
else % last diff outlier is the first post-jump index
    ind = jumpIdcs(end);
    fprintff('Warning: RTD jump detected - excluding measurements below %.2f[deg].\n', ldd(ind))
end

% group by LDD
lddForEst = ldd(ind:end);
rtdForEst = rtdPerFrame(ind:end);
minMaxLdd = minmax(lddForEst);
results.rtd.maxval = minMaxLdd(2);
results.rtd.minval = minMaxLdd(1);
results.rtd.nBins = nBins;
lddGrid = linspace(results.rtd.minval,results.rtd.maxval,nBins);
lddStep = lddGrid(2)-lddGrid(1);
rtdGrid = arrayfun(@(x) median(rtdForEst(abs(lddForEst-x)<=lddStep/2)), lddGrid);
tsenseGrid = arrayfun(@(x) median(tsense(abs(lddForEst-x)<=lddStep/2)), lddGrid);
results.rtd.refTemp = data.dfzRefTmp;
[~, ind] = min(abs(results.rtd.refTemp - lddGrid));
refRtd = rtdGrid(ind);
results.rtd.tmptrOffsetValues = -(rtdGrid-refRtd); % aligning to reference temperature
% TSense possible consideration
results.rtd.tsenseGrid = tsenseGrid;
rtdModelParams = calibParams.fwTable.extrap.rtdModel;
validIdcsByTSense = ~rtdModelParams.limitToTsense | ((results.rtd.tsenseGrid >= rtdModelParams.tsenseLims(1)) & (results.rtd.tsenseGrid <= rtdModelParams.tsenseLims(2)));

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(ldd, rtdPerFrame,'*');
    title('RTD(ldd) and Fitted line');
    grid on; xlabel('ldd Temperature'); ylabel('mean rtd');
    hold on
    plot(lddGrid, rtdGrid, '-o');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanRtd_Per_LDD_Temp'));
    ff = Calibration.aux.invisibleFigure;
    plot(ma,rtdPerFrame,'*');
    title('RTD(ma) and Fitted line');
    grid on;xlabel('ma Temperature');ylabel('mean rtd');
    hold on
    plot(ma,aMA*ma+bMA);
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanRtd_Per_MA_Temp'));
end

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    histogram(ldd,0:80.5)
    title('Frames Per Ldd Temperature Histogram'); grid on;xlabel('Ldd Temperature');ylabel('count');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Histogram_Frames_Per_Temp'));
end

%% Y Fix - groupByVBias2
validYFixFrames = timeVec >= calibParams.fwTable.yFix.ignoreNSeconds;
vbias2 = vBias(2,validYFixFrames);
minMaxVBias2 = minmax(vbias2);
maxVBias2 = minMaxVBias2(2);
minVBias2 = minMaxVBias2(1);
binEdges = linspace(minVBias2,maxVBias2,N);
dbin = binEdges(2)-binEdges(1);
binIndices = max(1,min(nBins,floor((vbias2-minVBias2)/dbin)+1));
refBinIndex = max(1,min(nBins,floor((regs.FRMW.dfzVbias(2)-minVBias2)/dbin)+1));
framesPerVBias2 = Calibration.thermal.medianFrameByTemp(framesData(validYFixFrames),nBins,binIndices);
if all(all(isnan(framesPerVBias2(refBinIndex,:,:))))
    fprintff('Self heat didn''t reach algo calibration vBias2. \n');
    table = [];
    return;
end

[results.angy.scale,results.angy.offset] = linearTransformToRef(framesPerVBias2(:,validCB,3),refBinIndex);
results.angy.minval = mean(binEdges(1:2));
results.angy.maxval = mean(binEdges(end-1:end));
results.angy.nBins = nBins;
jumpIdcs = detectJump(results.angy.offset, 'Yoffset', calibParams.fwTable.jumpDet, false, runParams);
if ~isempty(jumpIdcs)
    fprintff('Error: angy offset jump detected - failing unit.\n')
    table = [];
    return;
end

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    subplot(131)
    plot((binEdges(1:end-1)+binEdges(2:end))*0.5,results.angy.scale);
    title('AngYScale per vBias2'); xlabel('vBias2 (V)'); ylabel('AngYScale'); grid on;
    subplot(132)
    plot(timev,vBias(2,:));title('vBias2(t)'); xlabel('time [sec]'); ylabel('vBias2[v]'); grid on;
    subplot(133)
    plot((binEdges(1:end-1)+binEdges(2:end))*0.5,results.angy.offset);
    title('AngYOffset per vBias2'); xlabel('vBias2 (V)'); ylabel('AngYOffset'); grid on;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Scale and Offset Per vBias2'));
end

%% X Fix - groupByVBias1+3
vbias1 = vBias(1,:);
vbias3 = vBias(3,:);
[a,b] = linearTrans(vec(vbias1(startI:end)),vec(vbias3(startI:end)));

minmaxvbias1 = minmax(vbias1);
maxvbias1 = minmaxvbias1(2);
minvbias1 = minmaxvbias1(1);
p0 = [minvbias1,a*minvbias1 + b];
p1 = [maxvbias1,a*maxvbias1 + b];

t = linspaceCanonicalCenters(N);
tgal = (1/norm(p1-p0)^2)*(p1-p0)*([vbias1(:),vbias3(:)]-p0)';
binEdges = t;
dbin = binEdges(2)-binEdges(1);
binIndices = max(1,min(nBins,round(tgal/dbin)+1));
refBinTGal = (1/norm(p1-p0)^2)*(p1-p0)*([regs.FRMW.dfzVbias(1),regs.FRMW.dfzVbias(3)]-p0)';
refBinIndex = max(1,min(nBins,round(refBinTGal/dbin)+1));
framesPerVBias13 = Calibration.thermal.medianFrameByTemp(framesData,nBins,binIndices);
if all(all(isnan(framesPerVBias13(refBinIndex,:,:))))
    fprintff('Self heat didn''t reach algo calibration vbias1/3.\n');
    table = [];
    return;
end

[results.angx.scale,results.angx.offset] = linearTransformToRef(framesPerVBias13(:,validCB,2),refBinIndex);
results.angx.p0 = p0;
results.angx.p1 = p1;
results.angx.nBins = nBins;
jumpIdcs = detectJump(results.angx.offset, 'Xoffset', calibParams.fwTable.jumpDet, false, runParams);
if ~isempty(jumpIdcs)
    fprintff('Error: angx offset jump detected - failing unit.\n')
    table = [];
    return;
end

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    subplot(132);
    pEdges = p0+t'.*(p1-p0);
    plot(vbias1,vbias3); hold on; plot(pEdges(:,1),pEdges(:,2),'o');title('vBias3(vBias1)'); xlabel('vBias1');ylabel('vBias3');grid on;
    subplot(131);
    plot(results.angx.scale);
    title('AngXScale per point'); xlabel('bin index'); ylabel('AngXScale'); grid on;
    subplot(133);
    plot(results.angx.offset);
    title('AngXOffset per point'); xlabel('bin index'); ylabel('AngXOffset'); grid on;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Scale and Offset Per vBias13'));
end


%% RGB Fix - groupByLDDtemp
if (size(framesData(1).ptsWithZ,2) == 7) % RGB frames captures during heating stage
    nBinsRgb = calibParams.fwTable.nRowsRGB;
    ptsWithZ = reshape([framesData.ptsWithZ],560,7,[]);
    rgbCrnrsPerFrame = ptsWithZ(:,6:7,:);
    
    minMaxLdd4RGB = minmax(ldd);
    lddGridEdges = linspace(minMaxLdd4RGB(1),minMaxLdd4RGB(2),nBinsRgb+2);
    lddStepRgb = lddGridEdges(2)-lddGridEdges(1);
    lddGridRgb = lddStepRgb/2 + lddGridEdges(1:end-1);
    %{
% Debug
figure; stem(lddGridRgb,ones(size(lddGridRgb)),'g')
hold on;
stem(lddGridEdges,ones(size(lddGridEdges)),'r');
    %}
    rgbGrid = NaN(size(rgbCrnrsPerFrame,1),size(rgbCrnrsPerFrame,2),nBinsRgb+1);
    for k = 1:length(lddGridRgb)
        idcs = abs(ldd - lddGridRgb(k)) <= lddStepRgb/2;
        if ~sum(idcs)
            continue;
        end
        rgbGrid(:,:,k) = nanmedian(rgbCrnrsPerFrame(:,:,idcs),3);
    end
    referencePts = rgbGrid(:,:,end);
    scaleCosParam = nan(nBinsRgb,1);
    scaleSineParam = nan(nBinsRgb,1);
    transXparam = nan(nBinsRgb,1);
    transYparam = nan(nBinsRgb,1);
    %%
    for k = 1:nBinsRgb
        matchedPoints2 = referencePts;
        matchedPoints1 = rgbGrid(:,:,k);
        ixNotNanBoth = ~isnan(matchedPoints1(:,1)) & ~isnan(matchedPoints2(:,1));
        if ~sum(ixNotNanBoth)
            continue;
        end
        matchedPoints1 = matchedPoints1(ixNotNanBoth,:);
        matchedPoints2 = matchedPoints2(ixNotNanBoth,:);
        tform = fitgeotrans(matchedPoints1,matchedPoints2, 'nonreflectivesimilarity');
        scaleCosParam(k,1) = tform.T(1,1);
        scaleSineParam(k,1) = tform.T(2,1);
        transXparam(k,1) = tform.T(3,1);
        transYparam(k,1) = tform.T(3,2);
    end
    
    results.rgb.thermalTable = [scaleCosParam,scaleSineParam,transXparam,transYparam];
    results.rgb.referenceTemp = lddGridRgb(end);
    results.rgb.minTemp = minMaxLdd4RGB(1);
end

%% Table generation
angXscale       = vec(results.angx.scale);
angXoffset      = vec(results.angx.offset);
angYscale       = vec(results.angy.scale);
angYoffset      = vec(results.angy.offset);
destTmprtOffset = vec(results.rtd.tmptrOffsetValues);
    
% Convert to dsm values
dsmXscale   = angXscale*regs.EXTL.dsmXscale;
dsmXoffset  = (regs.EXTL.dsmXoffset*dsmXscale-2048*angXscale+angXoffset+2048)./dsmXscale;
dsmYscale   = angYscale*regs.EXTL.dsmYscale;
dsmYoffset  = (regs.EXTL.dsmYoffset*dsmYscale-2048*angYscale+angYoffset+2048)./dsmYscale;

% table organization
table = [dsmXscale,...
            dsmYscale,...
            dsmXoffset,...
            dsmYoffset,...
            destTmprtOffset];
table = fillInnerNans(table);   
table = fillStartNans(table);   
table = flipud(fillStartNans(flipud(table)));   

if calibParams.fwTable.yFix.bypass
   table(:,2) = regs.EXTL.dsmYscale;
   table(:,4) = regs.EXTL.dsmYoffset;
end

% extrapolation
vBiasLims               = extrapolateVBiasLimits(results, ldd(startI:end), vBias(:,startI:end), calibParams, runParams);
[table, results]        = extrapolateTable(table, results, vBiasLims, calibParams, runParams);
results.rtd.origMinval  = results.rtd.minval;
results.rtd.origMaxval  = results.rtd.maxval;
results.rtd.minval      = calibParams.fwTable.tempBinRange(1);
results.rtd.maxval      = calibParams.fwTable.tempBinRange(2);
results.angy.origMinval = results.angy.minval;
results.angy.origMaxval = results.angy.maxval;
results.angy.minval     = vBiasLims(2,1);
results.angy.maxval     = vBiasLims(2,2);
results.angx.origP0     = results.angx.p0;
results.angx.origP1     = results.angx.p1;
results.angx.p0         = vBiasLims([1,3],1)';
results.angx.p1         = vBiasLims([1,3],2)';
results.table           = table;

if ~isempty(runParams) && isfield(runParams, 'outputRawData') && runParams.outputRawData
    results.raw.vbias1      = linspace(results.angx.origP0(1), results.angx.origP1(1), nBins);
    results.raw.dsmXscale   = dsmXscale;
    results.raw.dsmXoffset  = dsmXoffset;
    results.raw.vbias2      = linspace(results.angy.origMinval, results.angy.origMaxval, nBins);
    results.raw.dsmYscale   = dsmYscale;
    results.raw.dsmYoffset  = dsmYoffset;
    results.raw.ldd         = ldd;
    results.raw.rtd         = -(rtdPerFrame-refRtd);
    results.raw.refRtd      = refRtd;
    results.raw.frameTime   = timev;
end

if ~isempty(runParams)
    v1Orig = linspace(results.angx.origP0(1), results.angx.origP1(1), nBins);
    v1 = linspace(results.angx.p0(1), results.angx.p1(1), nBins);
    v3 = linspace(results.angx.p0(2), results.angx.p1(2), nBins);
    tickIdcs = [1,9,17,25,32,40,48];
    % angX scale
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(v1Orig, dsmXscale, '*')
    plot(v1Orig, dsmXscale, '-o')
    plot(v1, table(:,1), '.-', 'linewidth', 2)
    set(gca, 'xtick', v1(tickIdcs))
    set(gca, 'xticklabel', arrayfun(@(x) sprintf('(%.2f,%.2f)', v1(x), v3(x)), tickIdcs, 'UniformOutput', false))
    grid on, xlabel('(Vbias1,Vbias3) [V]'), ylabel('DSM X scale [1/deg]'), title('DSM X scale vs. (vBias1,vBias3)');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables',sprintf('X_scale_table'),1);
    % angY scale
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYscale, '*')
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYscale, '-o')
    plot(linspace(results.angy.minval, results.angy.maxval, nBins), table(:,2), '.-', 'linewidth', 2)
    grid on, xlabel('Vbias2 [V]'), ylabel('DSM Y scale [1/deg]'), title('DSM Y scale vs. vBias2');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables',sprintf('Y_scale'),1);
    % angX offset
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(v1Orig, dsmXoffset, '*')
    plot(v1Orig, dsmXoffset, '-o')
    plot(v1, table(:,3), '.-', 'linewidth', 2)
    set(gca, 'xtick', v1(tickIdcs))
    set(gca, 'xticklabel', arrayfun(@(x) sprintf('(%.2f,%.2f)', v1(x), v3(x)), tickIdcs, 'UniformOutput', false))
    grid on, xlabel('(Vbias1,Vbias3) [V]'), ylabel('DSM X offset [deg]'), title('DSM X offset vs. (vBias1,vBias3)');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables',sprintf('X_offset'),1);
    % angY offset
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYoffset, '*')
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYoffset, '-o')
    plot(linspace(results.angy.minval, results.angy.maxval, nBins), table(:,4), '.-', 'linewidth', 2)
    grid on, xlabel('Vbias2 [V]'), ylabel('DSM Y offset [deg]'), title('DSM Y offset vs. vBias2');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables',sprintf('Y_offset'),1);
    % RTD
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(ldd, -(rtdPerFrame-refRtd),'*');
    hPlot = plot(lddGrid(validIdcsByTSense), -(rtdGrid(validIdcsByTSense)-refRtd),'-o','markersize',3);
    set(hPlot, 'markerfacecolor', sqrt(get(hPlot,'color')))
    plot(linspace(results.rtd.minval, results.rtd.maxval, nBins), table(:,5), '.-', 'linewidth', 2)
    grid on, xlabel('Ldd Temperature [deg]'), ylabel('RTD [mm]'), title('RTD vs. LDD');
    legend('raw (w.r.t. reference)', 'table (orig)', 'table (extrapolated)')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables',sprintf('RTD'),1);
end
assert(~any(isnan(table(:))),'Thermal table contains nans \n');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [anga,angb] = linearTransformToRef(framesPerTemperature,refBinIndex)

nFrames = size(framesPerTemperature,1);  
target = framesPerTemperature(refBinIndex,:);
validT = ~isnan(target);
for i = 1:nFrames
    source = framesPerTemperature(i,:);
    valid = logical((~isnan(source)) .* validT);
    
    if any(valid)
        [anga(i),angb(i)] = linearTrans(vec(source(valid)),vec(target(valid)));
    else
        anga(i) = nan;
        angb(i) = nan;
    end
    
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [a,b] = linearTrans(x1,x2)
A = [x1,ones(size(x1))];
res = inv(A'*A)*A'*x2;
a = res(1);
b = res(2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function table = fillStartNans(table)
    for i = 1:size(table,2)
        ni = find(~isnan(table(:,i)),1);
        if ni>1
            table(1:ni-1,i) = table(ni,i);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tableNoInnerNans = fillInnerNans(table)
    tableNoInnerNans = table;
    
    for i = 1:size(table,2)
        col = table(:,i);
        nanRows = isnan(col);
        rowId = (1:size(table,1))';
        tableValid = col(~nanRows);
        rowValid = rowId(~nanRows);
        rowInvalid = rowId(nanRows);
        newVals = interp1q(rowValid,tableValid,rowInvalid);
        tableNoInnerNans(nanRows,i) = newVals;
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function verifyThermalSweepValidity(ldd, startI, warmUpParams)
if (startI >= 0.5*length(ldd))
    error('Too few frames left for thermal calibration (%d taken, %d ignored)', length(ldd), startI-1)
end
if (diff(warmUpParams.requiredTmptrRange)>0) % valid obligatory range
    if (min(ldd)>warmUpParams.requiredTmptrRange(1)) || (max(ldd)<warmUpParams.requiredTmptrRange(2))
        error('Thermal sweep %.1f-%.1f missed obligatory range [%d,%d]', min(ldd), max(ldd), warmUpParams.requiredTmptrRange(1), warmUpParams.requiredTmptrRange(2))
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function vBiasLims = extrapolateVBiasLimits(results, ldd, vBias, calibParams, runParams)

vBiasLims = zeros(3,2);

% vBias2
coef2 = polyfit(ldd, vBias(2,:), 2);
fit2 = @(x) coef2(1)*x.^2 + coef2(2)*x + coef2(3);
vBiasLims(2,:) = fit2(calibParams.fwTable.tempBinRange);

% vBias1/3
p0 = results.angx.p0;
p1 = results.angx.p1;
tgal = (1/norm(p1-p0)^2)*(p1-p0)*(vBias([1,3],:)'-p0)';
coef13 = polyfit(ldd, tgal, 2);
fit13 = @(x) coef13(1)*x.^2 + coef13(2)*x + coef13(3);
tgalExtrapLims = fit13(calibParams.fwTable.tempBinRange);
vBiasLims([1,3],:) = p0' + (p1-p0)'*tgalExtrapLims;

if calibParams.fwTable.extrap.expandVbiasLims
    vBiasSpan = diff(vBiasLims,[],2);
    vBiasLims = vBiasLims + calibParams.fwTable.extrap.expandFactor*vBiasSpan*[-1,1];
end

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure; hold all
    lddExt = linspace(calibParams.fwTable.tempBinRange(1), calibParams.fwTable.tempBinRange(2), 48);
    plot(ldd, vBias(1,:), 'b.-'), plot(lddExt, p0(1)+(p1(1)-p0(1))*fit13(lddExt), 'c-o')
    plot(ldd, vBias(2,:), '.-', 'color', [0,0.5,0]),  plot(lddExt, fit2(lddExt), 'g-o')
    plot(ldd, vBias(3,:), 'r.-'),  plot(lddExt, p0(2)+(p1(2)-p0(2))*fit13(lddExt), 'm-o')
    plot(calibParams.fwTable.tempBinRange, vBiasLims(1,:), 'bp')
    plot(calibParams.fwTable.tempBinRange, vBiasLims(2,:), 'p', 'color', [0,0.5,0])
    plot(calibParams.fwTable.tempBinRange, vBiasLims(3,:), 'rp')
    grid on, xlabel('LDD [deg]'), ylabel('vBias [V]'), legend('vBias1','extrap','vBias2','extrap','vBias3','extrap','vBias1Lims','vBias2Lims','vBias3Lims')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables','vBiasLimExtrap');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = linspaceCanonicalCenters(n)
% generates grid for which bin centers are evenly-spaced between 0 and 1
xMin = -(2*n-2)/((2*n-3)^2-1);
xMax = (2*n-2)*(2*n-3)/((2*n-3)^2-1);
x = linspace(xMin, xMax, n);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [table, results] = extrapolateTable(table, results, vBiasLims, calibParams, runParams)

extrapParams = calibParams.fwTable.extrap;

% angy extrapolation
origGridY = linspace(results.angy.minval, results.angy.maxval, results.angy.nBins);
extrapGridY = linspace(vBiasLims(2,1), vBiasLims(2,2), results.angy.nBins);
extrapYScale = polyExtrap(origGridY', table(:,2), extrapGridY, extrapParams.yScaleOrder);
extrapYOffset = polyExtrap(origGridY', table(:,4), extrapGridY, extrapParams.yOffsetOrder);

% angx extrapolation
p0 = results.angx.p0;
p1 = results.angx.p1;
tgal = (1/norm(p1-p0)^2)*(p1-p0)*(vBiasLims([1,3],:)'-p0)';
origGridX = linspace(0, 1, results.angx.nBins);
extrapGridX = linspace(tgal(1), tgal(2), results.angx.nBins);
extrapXScale = polyExtrap(origGridX', table(:,1), extrapGridX, extrapParams.xScaleOrder);
extrapXOffset = polyExtrap(origGridX', table(:,3), extrapGridX, extrapParams.xOffsetOrder);

% rtd extrap
origGridRtd = linspace(results.rtd.minval, results.rtd.maxval, results.rtd.nBins);
if extrapParams.rtdModel.limitToTsense
    validIdcs = (results.rtd.tsenseGrid >= extrapParams.rtdModel.tsenseLims(1)) & (results.rtd.tsenseGrid <= extrapParams.rtdModel.tsenseLims(2));
    origGridRtd = origGridRtd(validIdcs);
    origRtdTable = table(validIdcs,5);
else
    origRtdTable = table(:,5);
end
if extrapParams.rtdModel.hypoTest % use hypothesis testing
    rtdFitRef = polyExtrap(origGridRtd', origRtdTable, origGridRtd', extrapParams.rtdModel.refOrder); % default model
    rtdFixedRef = origRtdTable-rtdFitRef;
    rmsRef = rms(rtdFixedRef);
    [rtdFitTest, polyCoefTest] = polyExtrap(origGridRtd', origRtdTable, origGridRtd', extrapParams.rtdModel.testOrder); % test model
    rtdFixedTest = origRtdTable-rtdFitTest;
    rmsTest = rms(rtdFixedTest);
    rmsRatio = rmsTest/rmsRef;
    if extrapParams.rtdModel.failPosLeadCoef && (polyCoefTest(1) > 0) % test model doesn't fit empirical knowledge
        validTestFit = 0; % ignore test model
    else
        validTestFit = 1; % accept test model
    end
    if validTestFit && (rmsRatio < extrapParams.rtdModel.rmsRatioThreshold) % test model significantly better than ref model
        rtdModelOrder = extrapParams.rtdModel.altOrder; % alternative model
    else
        rtdModelOrder = extrapParams.rtdModel.refOrder; % default model
    end
    results.rtd.modelsRmsRatio = rmsRatio;
    results.rtd.modelOrder = rtdModelOrder;
else % avoid hypothesis testing - use default assumption
    rtdModelOrder = extrapParams.rtdModel.refOrder;
end
extrapGridRtd = linspace(calibParams.fwTable.tempBinRange(1), calibParams.fwTable.tempBinRange(2), results.rtd.nBins);
extrapRtd = polyExtrap(origGridRtd', origRtdTable, extrapGridRtd, rtdModelOrder);

% debug
if ~isempty(runParams) && extrapParams.rtdModel.hypoTest
    polyOrdLeg = {'linear', 'quadratic', 'cubic', 'quartic'};
    validTestLeg = {'p(1)>0, ', ''};
    ff = Calibration.aux.invisibleFigure; hold all
    plot(origGridRtd', table(:,5), '-o')
	plot(origGridRtd', rtdFitRef, '-')
	plot(origGridRtd', rtdFitTest, '--')
    grid on, xlabel('LDD [deg]'), ylabel('RTD [mm]')
    legend('raw table', sprintf('%s (RMS %.2f)',polyOrdLeg{extrapParams.rtdModel.refOrder},rmsRef), sprintf('%s (RMS %.2f)',polyOrdLeg{extrapParams.rtdModel.testOrder},rmsTest))
    title(sprintf('RMS ratio = %.2f, %s%s model chosen', rmsRatio, validTestLeg{validTestFit+1}, polyOrdLeg{rtdModelOrder}))
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables','rtdModel');
end

% table update
table(:,1) = extrapXScale;
table(:,2) = extrapYScale;
table(:,3) = extrapXOffset;
table(:,4) = extrapYOffset;
table(:,5) = extrapRtd;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [extrapVals, polyCoef] = polyExtrap(origGrid, origVals, extrapGrid, polyOrder)
polyCoef = polyfit(origGrid, origVals, polyOrder);
switch polyOrder
    case 1
        polyFunc = @(x) polyCoef(1)*x + polyCoef(2);
    case 2
        polyFunc = @(x) polyCoef(1)*x.^2 + polyCoef(2)*x + polyCoef(3);
    case 3
        polyFunc = @(x) polyCoef(1)*x.^3 + polyCoef(2)*x.^2 + polyCoef(3)*x + polyCoef(4);
    otherwise
        error('polyExtrap currently supports orders 1-3 only')
end
extrapVals = polyFunc(extrapGrid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function jumpIdcs = detectJump(dataVec, paramName, jumpDetParams, doSmooth, runParams)
% smooth differentiation
if doSmooth
    nSmooth = jumpDetParams.nSmooth;
else
    nSmooth = 1;
end
dataVecSmooth = smooth(dataVec, nSmooth);
dataVecSmooth = dataVecSmooth(ceil(nSmooth/2):nSmooth:end);
smoothDiff = diff(dataVecSmooth);
nPts = length(smoothDiff);
% detrending
sdRightNeighbor = smoothDiff([2:end,end]);
sdLeftNeighbor = smoothDiff([1,1:end-1]);
rightWeight = abs(smoothDiff-sdLeftNeighbor)./(abs(smoothDiff-sdLeftNeighbor)+abs(smoothDiff-sdRightNeighbor));
sdTrend = sdRightNeighbor.*rightWeight + sdLeftNeighbor.*(1-rightWeight);
sdDetrended = smoothDiff - sdTrend;
% jump detection
absDeviation = abs(sdDetrended);
deviationPerc = min(jumpDetParams.deviationPerc, 100*(nPts-jumpDetParams.minNumOutliers)/nPts);
jumpDetThreshold = jumpDetParams.thFactor * prctile(absDeviation, deviationPerc);
isOutlier = (absDeviation >= jumpDetThreshold);
isJump = isOutlier;
jumpIdcsSmooth = find(isJump);
if ~isempty(jumpIdcsSmooth)
    jumpIdcs = ceil(nSmooth/2)+((jumpIdcsSmooth+1)-1)*nSmooth;
else
    jumpIdcs = [];
end
% visualization
if ~isempty(runParams) && ~isempty(jumpIdcs)
    ff = Calibration.aux.invisibleFigure;
    subplot(131), hold all
    plot(dataVec, 'b.-'),       plot(ceil(nSmooth/2):nSmooth:length(dataVec), dataVecSmooth, 'c-o')
    grid on, legend('raw', 'smooth'), title(paramName)
    subplot(132), hold all
    plot(smoothDiff, 'b.-'),    plot(sdTrend, 'c-o')
    grid on, legend('smooth diff', 'trend')
    subplot(133), hold all
    plot(sdDetrended, 'k-o'),   plot([1,length(sdDetrended)], ones(2,1)*[-1,1]*jumpDetThreshold, 'm--')
    plot(jumpIdcsSmooth, sdDetrended(jumpIdcsSmooth), 'ro', 'markerfacecolor', 'm')
    grid on, legend('detrended', 'low threshold', 'high threshold', 'jump detected')
    Calibration.aux.saveFigureAsImage(ff,runParams,'JumpDetection',paramName,1);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function isValid = checkTemperaturesValidity(ldd, ma, tsense, shtw2, fprintff)
isValid = true;
if (max(ldd)==min(ldd))
    isValid = false;
    fprintff('Error in temperature reading: LDD temperature is constant over frames.\n');
    return
end
if (max(ma)==min(ma))
    isValid = false;
    fprintff('Error in temperature reading: MA temperature is constant over frames.\n');
    return
end
if (max(tsense)==min(tsense))
    isValid = false;
    fprintff('Error in temperature reading: TSense temperature is constant over frames.\n');
    return
end
if (max(shtw2)==min(shtw2))
    isValid = false;
    fprintff('Error in temperature reading: SHTW2 temperature is constant over frames.\n');
    return
end
end
