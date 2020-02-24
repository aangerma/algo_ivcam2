function [table, results, errorCode] = generateFWTable(data, calibParams, runParams, fprintff)
% Bin frames according to fw loop requirment.
% Generate a fix for angles and an offset for rtd


%% Preparations
errorCode = NaN; % default
framesData = data.framesData;
timeVec = [framesData.time];
tempData = [framesData.temp];
ldd = [tempData.ldd];
vBias = reshape([framesData.vBias],3,[]);
iBias = reshape([framesData.iBias],3,[]);
regs = data.regs;

nBins = calibParams.fwTable.nRows;
N = nBins+1;

validPerFrame = arrayfun(@(x) ~isnan(x.ptsWithZ(:,1)),data.framesDataShort,'UniformOutput',false)';
validPerFrame = cell2mat(validPerFrame);
validCBShort = all(validPerFrame,2);

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
if calibParams.warmUp.checkTmptrSensors && ~checkTemperaturesValidity(ldd, ma, tsense, shtw2, fprintff)
    results = [];
    table = [];
    errorCode = -1;
    return;
end


%% IR statistics
if isfield(framesData, 'irStat')
    irData = [framesData.irStat];
    irMean = [irData.mean];
    irStd = [irData.std];
    irNumPix = [irData.nPix];
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
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
    % check for malfunctioning flyback
    if ~validFlyback(ldd, irMean, calibParams.fwTable.flyback, runParams)
        results = [];
        table = [];
        errorCode = -2;
        return
    end
end


%% RTD fix
rtdPerFrame = arrayfun(@(x) nanmean(x.ptsWithZ(validCB,1)),framesData);
rtdPerFrameAlignedWithShortCorners = arrayfun(@(x) nanmean(x.ptsWithZ(validCB & validCBShort,1)),framesData);

% legacy
startI = calibParams.fwTable.nFramesToIgnore+1;
verifyThermalSweepValidity(ldd, startI, calibParams.warmUp)
[aMA,bMA] = linearTrans(vec(ma(startI:end)),vec(rtdPerFrame(startI:end)));
results.ma.slope = aMA;

% % jump detection
% jumpIdcs = detectJump(rtdPerFrame, 'RTD', calibParams.fwTable.jumpDet, true, runParams);
% if ~isempty(jumpIdcs)
%     fprintff('Error: RTD offset jump detected - failing unit.\n')
%     table = [];
%     errorCode = -3;
%     return;
% end

% group by LDD
lddForEst = ldd;
rtdForEst = rtdPerFrame;
rtdForEstWithShortCorners = rtdPerFrameAlignedWithShortCorners;
if calibParams.fwTable.extrap.rtdModel.skipInterpolation % use final grid from start
    results.rtd.maxval = calibParams.fwTable.tempBinRange(2);
    results.rtd.minval = calibParams.fwTable.tempBinRange(1);
else % use finer grid prior to extrapolation (as in angX & angY)
    results.rtd.maxval = max(lddForEst);
    results.rtd.minval = min(lddForEst);
end
results.rtd.nBins = nBins;
lddGrid = linspace(results.rtd.minval,results.rtd.maxval,nBins);
lddStep = lddGrid(2)-lddGrid(1);
rtdGrid = arrayfun(@(x) median(rtdForEst(abs(lddForEst-x)<=lddStep/2)), lddGrid);
rtdGridWithShortCorners = arrayfun(@(x) median(rtdForEstWithShortCorners(abs(lddForEst-x)<=lddStep/2)), lddGrid);
results.rtd.refTemp = data.dfzRefTmp;
[~, ind] = min(abs(results.rtd.refTemp - lddGrid));
refRtd = rtdGrid(ind);
refLdd = lddGrid(ind);
refRtdForShortCal = rtdGridWithShortCorners(ind);
results.rtd.tmptrOffsetValues = -(rtdGrid-refRtd); % aligning to reference temperature

[results.rtd.tmptrOffsetValuesShort,lddGrid,rtdInterpolated,lddShort,rtdShort] = rtdFixForShort(data,calibParams,validCB & validCBShort,refLdd,refRtdForShortCal);

% if ~isempty(runParams) && isfield(runParams, 'outputFolder')
%     ff = Calibration.aux.invisibleFigure;
%     plot(ldd, rtdPerFrame,'*');
%     title('RTD(ldd) and Fitted line');
%     grid on; xlabel('ldd Temperature'); ylabel('mean rtd');
%     hold on
%     plot(lddGrid, rtdGrid, '-o');
%     plot(lddShort,rtdShort,'*');
%     plot(lddGrid, rtdInterpolated, '-o');
% 
%     Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanRtd_Per_LDD_Temp'));
%     ff = Calibration.aux.invisibleFigure;
%     plot(ma,rtdPerFrame,'*');
%     title('RTD(ma) and Fitted line');
%     grid on;xlabel('ma Temperature');ylabel('mean rtd');
%     hold on
%     plot(ma,aMA*ma+bMA);
%     Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanRtd_Per_MA_Temp'));
% end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    histogram(ldd,0:80.5)
    title('Frames Per Ldd Temperature Histogram'); grid on;xlabel('Ldd Temperature');ylabel('count');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Histogram_Frames_Per_Temp'));
end


%% Y Fix - groupByVBias2
validYFixFrames = timeVec >= calibParams.fwTable.yFix.ignoreNSeconds;
assert(any(validYFixFrames), sprintf('Test is too short (%.0f[sec]), left without Y samples after ignoring first %d[sec]', max(timeVec), calibParams.fwTable.yFix.ignoreNSeconds));
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
    errorCode = -4;
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
    errorCode = -3;
    return;
end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    subplot(131)
    plot((binEdges(1:end-1)+binEdges(2:end))*0.5,results.angy.scale);
    title('AngYScale per vBias2'); xlabel('vBias2 (V)'); ylabel('AngYScale'); grid on;
    subplot(132)
    plot(timeVec,vBias(2,:));title('vBias2(t)'); xlabel('time [sec]'); ylabel('vBias2[v]'); grid on;
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
    errorCode = -4;
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
    errorCode = -3;
    return;
end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
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
    
    humid = [tempData.shtw2];
    minMaxHum4RGB = [calibParams.fwTable.tempBinRangeRGB(1) calibParams.fwTable.tempBinRangeRGB(2)];
    humGridEdges = linspace(minMaxHum4RGB(1),minMaxHum4RGB(2),nBinsRgb+2);
    humStepRgb = humGridEdges(2)-humGridEdges(1);
    humGridRgb = humStepRgb/2 + humGridEdges(1:end-1);
    rgbGrid = NaN(size(rgbCrnrsPerFrame,1),size(rgbCrnrsPerFrame,2),nBinsRgb+1);
    for k = 1:length(humGridRgb)
        idcs = abs(humid - humGridRgb(k)) <= humStepRgb/2;
        if ~sum(idcs)
            continue;
        end
        rgbGrid(:,:,k) = nanmedian(rgbCrnrsPerFrame(:,:,idcs),3);
        indexOfMaxTemp = k;
    end
    if isempty(indexOfMaxTemp)
        fprintff('Error: no points within temperature range in RGB thermal fix - failing unit.\n');
        errorCode = -5;
        return;
    end
    referencePts = rgbGrid(:,:,indexOfMaxTemp);
    scaleCosParam = NaN(nBinsRgb,1);
    scaleSineParam = NaN(nBinsRgb,1);
    transXparam = NaN(nBinsRgb,1);
    transYparam = NaN(nBinsRgb,1);

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
    rgbTable = fillInnerNans([scaleCosParam,scaleSineParam,transXparam,transYparam]);
    rgbTable = fillStartNans(rgbTable);
    rgbTable = flipud(fillStartNans(flipud(rgbTable)));
    results.rgb.thermalTable = rgbTable;
    results.rgb.minTemp = minMaxHum4RGB(1);
    results.rgb.maxTemp = minMaxHum4RGB(2);
    results.rgb.referenceTemp = humGridRgb(indexOfMaxTemp);
    results.rgb.isValid = 0;
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
if ~calibParams.fwTable.extrap.rtdModel.skipInterpolation % table is expected to be NaN free
    table = fillStartNans(table);
    table = flipud(fillStartNans(flipud(table)));
end

if calibParams.fwTable.yFix.bypass
   table(:,2) = regs.EXTL.dsmYscale;
   table(:,4) = regs.EXTL.dsmYoffset;
end

% extrapolation
results.pzr             = estHumFromPzrRes(shtw2(startI:end), vBias(:,startI:end)./iBias(:,startI:end), runParams, data.ctKillThr); 
results.pzr             = estVsenseFromPzrRes(data.vsenseData, runParams, results.pzr); 
vBiasLims               = extrapolateVBiasLimits(results, ldd(startI:end), vBias(:,startI:end), calibParams, runParams);
[table, results]        = extrapolateTable(table, results, vBiasLims, calibParams, runParams);
results.rtd.origMinval  = min(lddForEst);
results.rtd.origMaxval  = max(lddForEst);
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

% debug
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
    results.raw.frameTime   = timeVec;
    results.raw.hum         = shtw2;
end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    v1Orig = linspace(results.angx.origP0(1), results.angx.origP1(1), nBins);
    v1 = linspace(results.angx.p0(1), results.angx.p1(1), nBins);
    v3 = linspace(results.angx.p0(2), results.angx.p1(2), nBins);
    tickIdcs = [1,9,17,25,32,40,48];
    % LOS
    ff = Calibration.aux.invisibleFigure;
    % angX scale
    subplot(221)
    hold all
    plot(v1Orig, dsmXscale, '*')
    plot(v1Orig, dsmXscale, '-o')
    plot(v1, table(:,1), '.-', 'linewidth', 2)
    set(gca, 'xtick', v1(tickIdcs))
    set(gca, 'xticklabel', arrayfun(@(x) sprintf('(%.2f,%.2f)', v1(x), v3(x)), tickIdcs, 'UniformOutput', false))
    grid on, xlabel('(Vbias1,Vbias3) [V]'), ylabel('DSM X scale [1/deg]'), title('DSM X scale vs. (vBias1,vBias3)');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    % angY scale
    subplot(223)
    hold all
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYscale, '*')
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYscale, '-o')
    plot(linspace(results.angy.minval, results.angy.maxval, nBins), table(:,2), '.-', 'linewidth', 2)
    grid on, xlabel('Vbias2 [V]'), ylabel('DSM Y scale [1/deg]'), title('DSM Y scale vs. vBias2');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    % angX offset
    subplot(222)
    hold all
    plot(v1Orig, dsmXoffset, '*')
    plot(v1Orig, dsmXoffset, '-o')
    plot(v1, table(:,3), '.-', 'linewidth', 2)
    set(gca, 'xtick', v1(tickIdcs))
    set(gca, 'xticklabel', arrayfun(@(x) sprintf('(%.2f,%.2f)', v1(x), v3(x)), tickIdcs, 'UniformOutput', false))
    grid on, xlabel('(Vbias1,Vbias3) [V]'), ylabel('DSM X offset [deg]'), title('DSM X offset vs. (vBias1,vBias3)');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    % angY offset
    subplot(224)
    hold all
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYoffset, '*')
    plot(linspace(results.angy.origMinval, results.angy.origMaxval, nBins), dsmYoffset, '-o')
    plot(linspace(results.angy.minval, results.angy.maxval, nBins), table(:,4), '.-', 'linewidth', 2)
    grid on, xlabel('Vbias2 [V]'), ylabel('DSM Y offset [deg]'), title('DSM Y offset vs. vBias2');
    legend('raw', 'table (orig)', 'table (extrapolated)')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables',sprintf('LOS'),1);
    % RTD
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(ldd, -(rtdPerFrame-refRtd),'*');
    hPlot = plot(lddGrid, -(rtdGrid-refRtd),'-o','markersize',3);
    set(hPlot, 'markerfacecolor', sqrt(get(hPlot,'color')))
    plot(linspace(results.rtd.minval, results.rtd.maxval, nBins), table(:,5), '.-', 'linewidth', 2)
    grid on, xlabel('Ldd Temperature [deg]'), ylabel('RTD [mm]'), title('RTD vs. LDD');    
    plot(lddShort, interp1(lddGrid,results.rtd.tmptrOffsetValuesShort,lddShort),'o');
    plot(lddGrid, results.rtd.tmptrOffsetValuesShort,'-');
    legend('raw long (w.r.t. reference)', 'table long (orig)', 'table long (extrapolated)', 'raw short (w.r.t. reference)', 'table short')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables',sprintf('RTD'),1);
end
assert(~any(isnan(table(:))),'Thermal table contains nans \n');

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function isValid = validFlyback(ldd, irMean, fbParams, runParams)
isValid = true; % defualt
if fbParams.offTest.enable
    lddRes = fbParams.offTest.lddRes;
    lddNoEdges = ldd(ldd>=min(ldd)+lddRes/2 & ldd<=max(ldd)-lddRes/2);
    smoothIrMean = arrayfun(@(x) median(irMean(abs(ldd-x)<lddRes)), lddNoEdges);
    localIrStd = arrayfun(@(x) std(irMean(abs(ldd-lddNoEdges(x))<lddRes)-smoothIrMean(x)), 1:length(lddNoEdges));
    irWeightedDrift = cumsum(diff(smoothIrMean)./mean([localIrStd(1:end-1); localIrStd(2:end)],1));
    lddDiff = diff(lddNoEdges([1,end]));
    if (irWeightedDrift(end) < -fbParams.offTest.thrFactor*lddDiff)
        if ~isempty(runParams) && isfield(runParams, 'outputFolder')
            ff = Calibration.aux.invisibleFigure;
            subplot(121)
            hold on
            plot(ldd, irMean-smoothIrMean(1), 'b-')
            plot(lddNoEdges, smoothIrMean-smoothIrMean(1), 'c--')
            plot([lddNoEdges, NaN, lddNoEdges], [smoothIrMean+localIrStd, NaN, smoothIrMean-localIrStd]-smoothIrMean(1), 'r--')
            grid on; xlabel('LDD [deg]'); ylabel('IR drift'); legend('mean', 'smooth', 'STD margin'); title('IR in central white tiles');
            subplot(122)
            hold on
            plot(lddNoEdges(1:end-1), irWeightedDrift, 'b.-')
            plot(lddNoEdges([1,end-1]), -fbParams.offTest.thrFactor*lddDiff*ones(1,2), 'k--')
            grid on; xlabel('LDD [deg]'); ylabel('IR drift'); legend('weighted drift', 'threshold'); title('IR drift');
            Calibration.aux.saveFigureAsImage(ff,runParams,'Flyback','failure');
        end
        isValid = false;
        return
    end
end
if fbParams.stopTest.enable
    lddRes = fbParams.stopTest.lddRes;
    smoothIrMean = arrayfun(@(x) median(irMean(abs(ldd-x)<lddRes)), ldd);
    localIrStd = arrayfun(@(x) std(irMean(abs(ldd-x)<lddRes)-smoothIrMean(abs(ldd-x)<lddRes)), ldd);
    invalidIdcs = (localIrStd < fbParams.stopTest.threshold);
    if (sum(invalidIdcs) >= fbParams.stopTest.minNumBadIdcs)
        if ~isempty(runParams) && isfield(runParams, 'outputFolder')
            ff = Calibration.aux.invisibleFigure;
            subplot(211)
            hold on
            plot(ldd, irMean, '.-')
            plot(ldd, smoothIrMean, '.-')
            grid on; xlabel('LDD [deg]'); ylabel('IR'); legend('mean', 'smooth mean'); title('IR in central white tiles');
            subplot(212)
            hold on
            plot(ldd, localIrStd, '.-')
            plot(ldd, fbParams.stopTest.threshold*ones(size(ldd)), '.-')
            plot(ldd(invalidIdcs), localIrStd(invalidIdcs), 'k-x')
            grid on; xlabel('LDD [deg]'); ylabel('IR local STD'); legend('local STD', 'threshold', 'bad indices'); title(sprintf('IR STD within %.2f[deg] window', fbParams.stopTest.lddRes));
            Calibration.aux.saveFigureAsImage(ff,runParams,'Flyback','failure');
        end
        isValid = false;
        return
    end
end
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
if ~isempty(jumpIdcs) && ~isempty(runParams) && isfield(runParams, 'outputFolder')
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

function x = linspaceCanonicalCenters(n)
% generates grid for which bin centers are evenly-spaced between 0 and 1
xMin = -(2*n-2)/((2*n-3)^2-1);
xMax = (2*n-2)*(2*n-3)/((2*n-3)^2-1);
x = linspace(xMin, xMax, n);
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

function pzrResults = estHumFromPzrRes(hum, pzrRes, runParams, ctKillThr)

pzrRes = pzrRes/1e3; % [Kohm]
pzrResults = repmat(struct('humEstCoef', zeros(1,3)), [1,3]);
for iPzr = 1:3
    pzrResults(iPzr).humEstCoef = single(polyfit(pzrRes(iPzr,:), hum, 2));
end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure; hold all
    clrs = {'b', 'c'; [0,0.5,0], 'g'; 'r', 'm'};
    signsStr = {'','+','+'};
    lgnd = cell(1,7);
    resAx = linspace(0,10,1000);
    pzrResLims = minmax(pzrRes(:));
    for iPzr = 1:3
        coef = pzrResults(iPzr).humEstCoef;
        humAx = polyval(coef, resAx);
        idcs = find(humAx>=ctKillThr(1),1,'first')-1:find(humAx>=ctKillThr(2),1,'first');
        pzrResLims = [min(pzrResLims(1),resAx(idcs(1))), max(pzrResLims(2),resAx(idcs(end)))];
        plot(pzrRes(iPzr,:), hum, '.', 'color', clrs{iPzr,1})
        lgnd{2*iPzr-1} = sprintf('PZR%d', iPzr);
        plot(resAx(idcs), polyval(coef, resAx(idcs)), '-', 'color', clrs{iPzr,2})
        lgnd{2*iPzr} = sprintf('%.1f*x^2%s%.1f*x%s%.1f', coef(1), signsStr{sign(coef(2))+2}, coef(2), signsStr{sign(coef(3))+2}, coef(3));
    end
    plot(pzrResLims([1,2,1,1,2]), [ctKillThr(1)*ones(1,2), NaN, ctKillThr(2)*ones(1,2)], 'k--', 'linewidth', 2)
    lgnd{7} = 'CT kill threshold';
    grid on, xlabel('PZR resistance [Kohm]'), ylabel('Humidity temperature [deg]'), legend(lgnd,'Location','SouthEast'), title('PZR resistance-based temperature model')
    Calibration.aux.saveFigureAsImage(ff,runParams,'PZR','TmptrResistanceModel');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pzrResults = estVsenseFromPzrRes(vsenseData, runParams, pzrResults) 

iBias = cell2mat(cellfun(@(x) x.iBias, vsenseData, 'UniformOutput', false));
vBias = cell2mat(cellfun(@(x) x.vBias, vsenseData, 'UniformOutput', false));
pzrRes = (vBias./iBias)'/1e3; % [Kohm]
pzrVsense = (cell2mat(cellfun(@(x) x.vSesnePZR, vsenseData, 'UniformOutput', false)))';

for iPzr = 1:3
    pzrResults(iPzr).vsenseEstCoef = single(polyfit(pzrRes(iPzr,:), pzrVsense(iPzr,:), 2));
end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure; hold all
    clrs = {'b', 'c'; [0,0.5,0], 'g'; 'r', 'm'};
    signsStr = {'','+','+'};
    lgnd = cell(1,6);
    resAx = linspace(0,10,1000);
    for iPzr = 1:3
        coef = pzrResults(iPzr).vsenseEstCoef;
        vSenseAx = polyval(coef, resAx);
        lastVisitedInd = find(resAx>max(pzrRes(iPzr,:)),1,'first');
        if (vSenseAx(1)*vSenseAx(end) > 0) % line fit doesn't cross X-axis
            signChangeInd = 0;
        else
            signChangeInd = find(vSenseAx*vSenseAx(1)>=0,1,'last');
        end
        idcs = 1:min(length(vSenseAx), max(lastVisitedInd, signChangeInd) + 1);
        plot(pzrRes(iPzr,:), pzrVsense(iPzr,:), '.', 'color', clrs{iPzr,1})
        lgnd{2*iPzr-1} = sprintf('PZR%d', iPzr);
        plot(resAx(idcs), polyval(coef, resAx(idcs)), '-', 'color', clrs{iPzr,2})
        lgnd{2*iPzr} = sprintf('%.3f*x^2%s%.3f*x%s%.3f', coef(1), signsStr{sign(coef(2))+2}, coef(2), signsStr{sign(coef(3))+2}, coef(3));
    end
    grid on, xlabel('PZR resistance [Kohm]'), ylabel('PZR VSense [V]'), legend(lgnd,'Location','NorthEast'), title('PZR resistance-based VSense model')
    Calibration.aux.saveFigureAsImage(ff,runParams,'PZR','VsenseResistanceModel');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function vBiasLims = extrapolateVBiasLimits(results, ldd, vBias, calibParams, runParams)

vBiasLims = zeros(3,2);

% vBias2
coef2 = polyfit(ldd, vBias(2,:), 2);
vBiasLims(2,:) = polyval(coef2, calibParams.fwTable.tempBinRange);

% vBias1/3
p0 = results.angx.p0;
p1 = results.angx.p1;
tgal = (1/norm(p1-p0)^2)*(p1-p0)*(vBias([1,3],:)'-p0)';
coef13 = polyfit(ldd, tgal, 2);
tgalExtrapLims = polyval(coef13, calibParams.fwTable.tempBinRange);
vBiasLims([1,3],:) = p0' + (p1-p0)'*tgalExtrapLims;

if calibParams.fwTable.extrap.expandVbiasLims
    vBiasSpan = diff(vBiasLims,[],2);
    vBiasLims = vBiasLims + calibParams.fwTable.extrap.expandFactor*vBiasSpan*[-1,1];
end

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure; hold all
    lddExt = linspace(calibParams.fwTable.tempBinRange(1), calibParams.fwTable.tempBinRange(2), 48);
    plot(ldd, vBias(1,:), 'b.-'), plot(lddExt, p0(1)+(p1(1)-p0(1))*polyval(coef13, lddExt), 'c-o')
    plot(ldd, vBias(2,:), '.-', 'color', [0,0.5,0]),  plot(lddExt, polyval(coef2, lddExt), 'g-o')
    plot(ldd, vBias(3,:), 'r.-'),  plot(lddExt, p0(2)+(p1(2)-p0(2))*polyval(coef13, lddExt), 'm-o')
    plot(calibParams.fwTable.tempBinRange, vBiasLims(1,:), 'bp')
    plot(calibParams.fwTable.tempBinRange, vBiasLims(2,:), 'p', 'color', [0,0.5,0])
    plot(calibParams.fwTable.tempBinRange, vBiasLims(3,:), 'rp')
    grid on, xlabel('LDD [deg]'), ylabel('vBias [V]'), legend('vBias1','extrap','vBias2','extrap','vBias3','extrap','vBias1Lims','vBias2Lims','vBias3Lims')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Tables','vBiasLimExtrap');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [table, results] = extrapolateTable(table, results, vBiasLims, calibParams, runParams)

extrapParams = calibParams.fwTable.extrap;

% angy extrapolation
origVb2Grid = linspace(results.angy.minval, results.angy.maxval, results.angy.nBins);
extrapVb2Grid = linspace(vBiasLims(2,1), vBiasLims(2,2), results.angy.nBins);
extrapYScale = polyExtrap(origVb2Grid, table(:,2)', extrapVb2Grid, extrapParams.yScaleOrder);
extrapYOffset = polyExtrap(origVb2Grid, table(:,4)', extrapVb2Grid, extrapParams.yOffsetOrder);

% angx extrapolation
p0 = results.angx.p0;
p1 = results.angx.p1;
tgal = (1/norm(p1-p0)^2)*(p1-p0)*(vBiasLims([1,3],:)'-p0)';
origVb13Grid = linspace(0, 1, results.angx.nBins);
extrapVb13Grid = linspace(tgal(1), tgal(2), results.angx.nBins);
extrapXScale = polyExtrap(origVb13Grid, table(:,1)', extrapVb13Grid, extrapParams.xScaleOrder);
extrapXOffset = polyExtrap(origVb13Grid, table(:,3)', extrapVb13Grid, extrapParams.xOffsetOrder);

% rtd extrapolation
origLddGrid = linspace(results.rtd.minval, results.rtd.maxval, results.rtd.nBins);
extrapLddGrid = linspace(calibParams.fwTable.tempBinRange(1), calibParams.fwTable.tempBinRange(2), results.rtd.nBins);
lddStep = extrapLddGrid(2)-extrapLddGrid(1);
if extrapParams.rtdModel.skipInterpolation % use smoothed measurements within calibrated region, and limit extrapolation to non-calibrated regions
    extrapRtd = extrapOutsideCalibRegionOnly(table(:,5)', lddStep, extrapParams.rtdModel.outsideCal);
else % use extrapolation for entire range
    [rtdModelOrder, results] = chooseRtdModelOrder(origLddGrid, table(:,5), runParams, extrapParams.rtdModel, results);
    extrapRtd = polyExtrap(origLddGrid, table(:,5)', extrapLddGrid, rtdModelOrder);
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
extrapVals = polyval(polyCoef, extrapGrid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rtdTable = extrapOutsideCalibRegionOnly(rtdTable, lddStep, outsideExtrapParams)

numIdcsForExtrap = ceil(outsideExtrapParams.degreesToUseFromEdge/lddStep);

if isnan(rtdTable(1)) % lower region extrapolation is needed
    firstValidInd = find(~isnan(rtdTable),1);
    idcsForExtrap = firstValidInd+(0:numIdcsForExtrap-1);
    % ref model
    [refSlope, refOffset] = getExtrapSlopeAndOffset(idcsForExtrap, rtdTable, outsideExtrapParams.refOrderLow, firstValidInd);
    refExtrapVals = refSlope*(1:firstValidInd-1) + refOffset;
    % test model
    [testSlope, testOffset] = getExtrapSlopeAndOffset(idcsForExtrap, rtdTable, outsideExtrapParams.testOrderLow, firstValidInd);
    testExtrapVals = testSlope*(1:firstValidInd-1) + testOffset;
    % blend
    rtdTable(1:firstValidInd-1) = outsideExtrapParams.testPortionLow*testExtrapVals + (1-outsideExtrapParams.testPortionLow)*refExtrapVals;
end

if isnan(rtdTable(end)) % higher region extrapolation is needed
    rtdTable = fliplr(rtdTable); % for ease (use same algorithm as in lower region)
    firstValidInd = find(~isnan(rtdTable),1);
    idcsForExtrap = firstValidInd+(0:numIdcsForExtrap-1);
    % ref model
    [refSlope, refOffset] = getExtrapSlopeAndOffset(idcsForExtrap, rtdTable, outsideExtrapParams.refOrderHigh, firstValidInd);
    refExtrapVals = refSlope*(1:firstValidInd-1) + refOffset;
    % test model
    [testSlope, testOffset] = getExtrapSlopeAndOffset(idcsForExtrap, rtdTable, outsideExtrapParams.testOrderHigh, firstValidInd);
    testExtrapVals = testSlope*(1:firstValidInd-1) + testOffset;
    % blend
    rtdTable(1:firstValidInd-1) = outsideExtrapParams.testPortionHigh*testExtrapVals + (1-outsideExtrapParams.testPortionHigh)*refExtrapVals;
    rtdTable = fliplr(rtdTable);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [slope, offset] = getExtrapSlopeAndOffset(idcsForExtrap, tableForExtrap, polyOrd, ind)

coef = polyfit(idcsForExtrap,tableForExtrap(idcsForExtrap), polyOrd);
slope = 0;
for k = 1:polyOrd
    slope = slope + (polyOrd-(k-1))*coef(k)*(ind^(polyOrd-k));
end

if (polyOrd==1)
    offset = coef(2); % continuity is implied
else
    offset = tableForExtrap(ind) - slope*ind; % continuity should be maintained
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rtdModelOrder, results] = chooseRtdModelOrder(lddGrid, rtdGrid, runParams, rtdModelParams, results)

if rtdModelParams.hypoTest.enable % use hypothesis testing
    rtdFitRef = polyExtrap(lddGrid, rtdGrid', lddGrid, rtdModelParams.refOrder); % default model
    rmsRef = rms(rtdGrid-rtdFitRef);
    [rtdFitTest, polyCoefTest] = polyExtrap(lddGrid, rtdGrid', lddGrid, rtdModelParams.hypoTest.testOrder); % test model
    rmsTest = rms(rtdGrid-rtdFitTest);
    rmsRatio = rmsTest/rmsRef;
    if rtdModelParams.hypoTest.failPosLeadCoef && (polyCoefTest(1) > 0) % test model doesn't fit empirical knowledge
        validTestFit = 0; % ignore test model
    else
        validTestFit = 1; % accept test model
    end
    if validTestFit && (rmsRatio < rtdModelParams.hypoTest.rmsRatioThreshold) % test model significantly better than ref model
        rtdModelOrder = rtdModelParams.hypoTest.altOrder; % alternative model
    else
        rtdModelOrder = rtdModelParams.refOrder; % default model
    end
    results.rtd.modelsRmsRatio = rmsRatio;
    results.rtd.modelOrder = rtdModelOrder;
    % debug
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        polyOrdLeg = {'linear', 'quadratic', 'cubic', 'quartic'};
        validTestLeg = {'p(1)>0, ', ''};
        ff = Calibration.aux.invisibleFigure; hold all
        plot(origLddGrid, rtdGrid', '-o')
        plot(origLddGrid, rtdFitRef', '-')
        plot(origLddGrid, rtdFitTest', '--')
        grid on, xlabel('LDD [deg]'), ylabel('RTD [mm]')
        legend('raw table', sprintf('%s (RMS %.2f)',polyOrdLeg{rtdModelParams.refOrder},rmsRef), sprintf('%s (RMS %.2f)',polyOrdLeg{rtdModelParams.testOrder},rmsTest))
        title(sprintf('RMS ratio = %.2f, %s%s model chosen', rmsRatio, validTestLeg{validTestFit+1}, polyOrdLeg{rtdModelOrder}))
        Calibration.aux.saveFigureAsImage(ff,runParams,'Tables','rtdModel');
    end
else % avoid hypothesis testing - use default assumption
    rtdModelOrder = rtdModelParams.refOrder;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tmptrOffsetVector,lddGrid,rtdVectorForShortPreset,ldds,rtds] = rtdFixForShort(data,calibParams,validCB,refLddLong,refRtdLong)
    fd = Calibration.thermal.framesDataVectors(data.framesDataShort);
    ldds = fd.ldd;
    assert(all(sort(ldds)==ldds),'Ldd temperatures of short preset frames are not monitonically increasing!')
    rtds = squeeze(mean(fd.ptsWithZ(validCB,1,:),1));
    N = numel(ldds);
    lddGrid = linspace(calibParams.fwTable.tempBinRange(1),calibParams.fwTable.tempBinRange(2),calibParams.fwTable.nRows);
    polyOrder = 2;
    
    rtdPWParab = nan(N-2,numel(lddGrid));
    for k = 2:N-1
        c = polyfit(vec(ldds(k-1:k+1)),vec(rtds(k-1:k+1)),polyOrder);
        if k == 2
            lddGridInd = lddGrid <= ldds(k+1);
        elseif k == N-1
            lddGridInd = lddGrid >= ldds(k-1);
        else
            lddGridInd = lddGrid >= ldds(k-1) & lddGrid <= ldds(k+1);
        end
        rtdPWParab(k-1,lddGridInd) = polyval(c,lddGrid(lddGridInd));
    end
    rtdVectorForShortPreset = nanmean(rtdPWParab,1);
    rtdVectorForShortPreset = rtdVectorForShortPreset(:);
    
    rtdShortAtRef = interp1(lddGrid,rtdVectorForShortPreset,refLddLong);
    
    tmptrOffsetVector = -(rtdVectorForShortPreset - rtdShortAtRef) + (refRtdLong-rtdShortAtRef);
end
