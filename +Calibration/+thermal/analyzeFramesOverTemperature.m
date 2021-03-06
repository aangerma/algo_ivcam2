function [data ] = analyzeFramesOverTemperature(data, calibParams,runParams,fprintff,inValidationStage)
% Calculate the following metrics:
% ,minEGeom,maxeGeom,meaneGeom
% stdX,stdY,p2pY,p2pX

invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
data.framesData = data.framesData(~invalidFrames);

validFrames = arrayfun(@(x) Calibration.thermal.validFrame(x.ptsWithZ,calibParams), data.framesData);
data.framesData = data.framesData(validFrames);

tempData = [data.framesData.temp];
ldd = [tempData.ldd];
if isfield(tempData, 'shtw2') % ATC / ATV
    hum = [tempData.shtw2];
    tsense = [tempData.tsense];
else % Algo2Val
    hum = [tempData.humidity];
    tsense = [tempData.apdTmptr];
end
data.dfzRefTmp = max(ldd);

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    cornersRtdVsIRFigure(data,runParams);
end

nBins = calibParams.fwTable.nRows;
dLdd = (calibParams.fwTable.tempBinRange(2) - calibParams.fwTable.tempBinRange(1))/(nBins-1);
tmpBinEdges = linspace(calibParams.fwTable.tempBinRange(1),calibParams.fwTable.tempBinRange(2),nBins) - dLdd*0.5;
refBinIndex = 1+floor((data.dfzRefTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
tmpBinIndices = 1+floor((ldd-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));


framesPerTemperature = Calibration.thermal.medianFrameByTemp(data.framesData,nBins,tmpBinIndices);

data.processed.framesPerTemperature = framesPerTemperature;

if isfield(calibParams.gnrl, 'rgb') && isfield(calibParams.gnrl.rgb, 'doStream') && calibParams.gnrl.rgb.doStream
    plotRGB = 1;
else
    plotRGB = 0;
end

%% Temperature readings
if inValidationStage && ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ma = [tempData.ma];
    timeVec = [data.framesData.time];
    nFrames = length(timeVec);
    lgnd = {'LDD', 'MA', 'TSense (APD)', 'SHTW2 (HUM)', 'humidApdTempDiff', 'TS target', 'TS actual'};
    ff = Calibration.aux.invisibleFigure;
    hold all
    plot(timeVec, ldd, '.-')
    plot(timeVec, ma, '.-')
    plot(timeVec, tsense, '.-')
    plot(timeVec, hum, '.-')
    if isfield(tempData, 'humidity') % Algo2Val
        mc = [tempData.mc];
        plot(timeVec, mc, '.-')
        lgnd{5} = 'MC';
    else % ATC / ATV
        [~, indMinDiff] = min(hum-tsense); %TODO: obsolete?
        plot(timeVec(indMinDiff)*ones(1,2), [tsense(indMinDiff), hum(indMinDiff)], '.-')
        text(timeVec(indMinDiff), mean([tsense(indMinDiff), hum(indMinDiff)]), sprintf('%.2f', data.regs.FRMW.humidApdTempDiff))
    end
    if isfield(data.framesData, 'thermostream') && ~isempty([data.framesData.thermostream])
        tsData = [data.framesData.thermostream];
        plot(timeVec,[tsData.target], '.--')
        plot(timeVec,[tsData.temperature], '.--')
    end
    grid on, xlabel('time [sec]'), ylabel('temperature [deg]')
    legend(lgnd, 'Location', 'northwest')
    title(sprintf('Temperature readings (%d frames in total)', nFrames))
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('TemperatureReadings'));
end
%%

thermalResults = Calibration.thermal.plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdges,refBinIndex,runParams,inValidationStage,plotRGB);

validTemps = ~all(any(isnan(framesPerTemperature(:,:,:,1)),3),2);
assert(sum(validTemps)>1, 'Thermal sweep occupies less than 2 bins - this is incompatible with code later on')

validFramesData = framesPerTemperature(validTemps,:,:,1);
% validCBPoints = all(all(~isnan(validFramesData),3),1);
% validFramesData = validFramesData(:,validCBPoints,:);
isDataWithXYZ = (size(validFramesData,3)>=8); % hack for dealing with missing XYZ data (pointsWithZ(6:8)) in ATC
stdVals = nanmean(nanstd(validFramesData));


metrics = Calibration.thermal.calcThermalScores(data,calibParams,[data.regs.GNRL.imgVsize,data.regs.GNRL.imgHsize]);
if plotRGB && isfield(data,'camerasParams')
    [metrics] = analyzeNplotRgb(data,framesPerTemperature,tmpBinEdges,tmpBinIndices,hum,calibParams,runParams,metrics,inValidationStage,fprintff);
end


metrics.stdRtd = stdVals(1);
metrics.stdXim = stdVals(4);
metrics.stdYim = stdVals(5);
if isDataWithXYZ
    metrics.stdXmm = stdVals(6);
    metrics.stdYmm = stdVals(7);
    metrics.stdZmm = stdVals(8);
end

maxP2pVals = max(max(validFramesData,[],1)-min(validFramesData,[],1));
metrics.p2pRtd = maxP2pVals(1);
metrics.p2pXim = maxP2pVals(4);
metrics.p2pYim = maxP2pVals(5);
if isDataWithXYZ
    metrics.p2pXmm = maxP2pVals(6);
    metrics.p2pYmm = maxP2pVals(7);
    metrics.p2pZmm = maxP2pVals(8);
end

nTemps = size(validFramesData,1);
if ~isempty(calibParams.gnrl.cbGridSz)
    cbGridSz = calibParams.gnrl.cbGridSz;
    validCBPoints = ones(prod(cbGridSz),1);
else
    if isDataWithXYZ
        validCBPoints = all(all(~isnan(validFramesData(:,:,1:8)),3),1); % not including RGB data
    else
        validCBPoints = all(all(~isnan(validFramesData(:,:,1:5)),3),1); % not including RGB data
    end
    validCBPoints = reshape(validCBPoints,20,28);
    validRows = find(any((validCBPoints),2));
    validCols = find(any((validCBPoints),1));
    cbGridSz = [numel(validRows),numel(validCols)];
    validCBPoints(validRows, validCols) = true; % validating the entire blocking rectangle for the sake of grid calculations only
    validFramesData = validFramesData(:,validCBPoints(:),:);
end
if isDataWithXYZ % hack for dealing with missing XYZ data in validFramesData (pointsWithZ(6:8)) in ATC
    eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesData(i,:,6:8)), cbGridSz, calibParams.gnrl.cbSquareSz);
    getGid = @(x) x.absErrorMean;
    eGeomOverTemp = nan(1,numel(tmpBinEdges));
    eGeomOverTemp(validTemps) = arrayfun(@(i) getGid(eGeoms(i)), 1:nTemps);
    
    metrics.meanEGeom = nanmean(eGeomOverTemp);
    metrics.maxEGeom = max(eGeomOverTemp);
    metrics.minEGeom = min(eGeomOverTemp);
    
    if inValidationStage % Compare calibration to theoretical Fix
        legends = {'Post Fix (val)'};
    else
        legends = {'Pre Fix (cal)'};
    end
    
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        plot(tmpBinEdges,eGeomOverTemp)
        title('Heating Stage EGeom'); grid on;xlabel('degrees');ylabel('eGeom [mm]');legend(legends);
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('EGeomOverTemp'),1);
    end
    
    fd = Calibration.thermal.framesDataVectors(data.framesData);
    planeFits = @(i) planeFitData(squeeze(fd.ptsWithZ(fd.validCB,6:8,i)));
    fdPf = arrayfun(@(i) planeFits(i), 1:size(fd.ptsWithZ,3));
    
    metrics.meanTiltH = nanmean([fdPf.horizAngle]);
    metrics.meanTiltV = nanmean([fdPf.verticalAngle]);
    metrics.relativeTiltH = max([fdPf.horizAngle])-min([fdPf.horizAngle]);
    metrics.relativeTiltV = max([fdPf.verticalAngle])-min([fdPf.verticalAngle]);
    
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        subplot(1,2,1);
        plot(fd.ldd,[fdPf.horizAngle])
        title('Horizontal Tilt Over Ldd Temp'); grid on;xlabel('degrees');ylabel('tilt angle [deg]');legend(legends);
        subplot(1,2,2);
        plot(fd.ldd,[fdPf.verticalAngle])
        title('Vertical Tilt Over Ldd Temp'); grid on;xlabel('degrees');ylabel('tilt angle [deg]');legend(legends);
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('TiltOverTemp'),1);
    end
    
    
end
plotRtdOfShortVsLongPostFix(data,runParams);

if isfield(data.framesData, 'verticalSharpness')
    verticalSharpness = [data.framesData.verticalSharpness];
    metrics.bestVerticalSharpness = min(verticalSharpness);
    metrics.worstVerticalSharpness = max(verticalSharpness);
    if inValidationStage && ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        plot(ldd, verticalSharpness,'.-')
        title('Heating Stage Vertical Sharpness'); grid on; xlabel('LDD [deg]'); ylabel('mean transition length [pixels]');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('VerticalSharpness'),1);
    end
end

if isfield(data.framesData, 'verticalSharpnessRGB')
    verticalSharpnessRGB = [data.framesData.verticalSharpnessRGB];
    metrics.bestRGBVerticalSharpness = min(verticalSharpnessRGB);
    metrics.worstRGBVerticalSharpness = max(verticalSharpnessRGB);
    if inValidationStage && ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        plot(ldd(~isnan(verticalSharpnessRGB)), verticalSharpnessRGB(~isnan(verticalSharpnessRGB)),'.-')
        title('Heating Stage RGB Vertical Sharpness'); grid on; xlabel('LDD [deg]'); ylabel('mean transition length [pixels]');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('RGB_VerticalSharpness'),1);
    end
    
    horizontalSharpnessRGB = [data.framesData.horizontalSharpnessRGB];
    metrics.bestRGBHorizontalSharpness = min(horizontalSharpnessRGB);
    metrics.worstRGBHorizontalSharpness = max(horizontalSharpnessRGB);
    if inValidationStage && ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        plot(ldd(~isnan(horizontalSharpnessRGB)), horizontalSharpnessRGB(~isnan(horizontalSharpnessRGB)),'.-')
        title('Heating Stage RGB Horizontal Sharpness'); grid on; xlabel('LDD [deg]'); ylabel('mean transition length [pixels]');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('RGB_HorizontalSharpness'),1);
    end
end

if isfield(data.framesData, 'dac')
    dacData = [data.framesData.dac];
    dacPredicted = single([dacData.predicted]);
    dacActual = single([dacData.actual]);
    metrics.maxDacModelError = max(abs(dacActual-dacPredicted));
    if inValidationStage && ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        hold on
        plot(ldd, dacPredicted, '.--')
        plot(ldd, dacActual, '.-')
        title('Heating Stage DAC Model'); grid on; xlabel('LDD [deg]'); ylabel('DAC value (modulation ref)'); legend('predicted', 'actual')
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('DacModel'),1);
    end
end

metrics.thermalMaxRmsErrRtd = thermalResults.thermalMaxRmsErrRtd;
metrics.thermalMaxRmsErrX = thermalResults.thermalMaxRmsErrX;
metrics.thermalMaxRmsErrY = thermalResults.thermalMaxRmsErrY;
if plotRGB
    metrics.thermalMaxRmsErrRgbX = thermalResults.thermalMaxRmsErrRgbX;
    metrics.thermalMaxRmsErrRgbY = thermalResults.thermalMaxRmsErrRgbY;
end

data.results = metrics;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function s = planeFitData(vertices)
    [distError, p, ~] = Validation.aux.planeFitInternal(vertices(~isnan(vertices(:,1)),:));
    s.planeFitErrorRms = rms(distError);
    s.horizAngle = (90-atan2d(p(3),p(1)));
    s.verticalAngle = (90-atan2d(p(3),p(2)));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotRtdOfShortVsLongPostFix(data,runParams)
if ~isfield(data,'framesDataShort')
   return; 
end
fdLong = Calibration.thermal.framesDataVectors(data.framesData);
fdShort = Calibration.thermal.framesDataVectors(data.framesDataShort);
valid = fdLong.validCB & fdShort.validCB;
ff = Calibration.aux.invisibleFigure;
plot(fdLong.ldd,squeeze(nanmean(fdLong.ptsWithZ(valid,1,:),1)),'*')
hold on
plot(fdShort.ldd,squeeze(nanmean(fdShort.ptsWithZ(valid,1,:),1)),'o')
grid minor;
xlabel('ldd');
ylabel('mm');
title('Rtd Per frame Long/Short');
legend({'Long';'Short'});
Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Rtd_Short_Vs_Long'),1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [params] = prepareParams4UvMap(camerasParams)
params.depthRes = camerasParams.depthRes;
params.camera.rgbPmat = camerasParams.rgbPmat;
params.camera.rgbK = camerasParams.Krgb;
params.rgbDistort = camerasParams.rgbDistort;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [metrics] = analyzeNplotRgb(data,framesPerTemperature,tmpBinEdges,tmpBinIndices,hum,calibParams,runParams,metrics,inValidationStage,fprintff)
if isfield(calibParams.gnrl.rgb, 'fixRgbThermal') && calibParams.gnrl.rgb.fixRgbThermal
    fixRgbThermal = 1;
else
    fixRgbThermal = 0;
end
[params] = prepareParams4UvMap(data.camerasParams);
params.inValidationStage = inValidationStage;
uvResults = Calibration.thermal.calcThermalUvMap(framesPerTemperature,calibParams,params);
metrics.uvMeanRmse = nanmean(uvResults(:,1));
metrics.uvMaxErr = max(uvResults(:,2));
metrics.uvMaxErr95 = max(uvResults(:,3));
metrics.uvMinErr = min(uvResults(:,4));
if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    if ~params.inValidationStage
        legends = {'Pre Fix (cal)'};
    else
        legends = {'Post Fix (val)'};
    end
    
    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,uvResults(:,1));
    
    title('UV mapping RMSE vs Temperature'); grid on;xlabel('degrees');ylabel('UV RMSE [rgb pixels]'); axis square;
    if ~fixRgbThermal || ~data.rgb.isValid
        if isfield(data,'rgb')
            hold on;
            plot([data.rgb.rgbCalTemp,data.rgb.rgbCalTemp],[0,max(uvResults(:,1))],'k--','linewidth',2);
            legends{end+1} = 'Cal Humidity Temp';
        end
        legend(legends);
        Calibration.aux.saveFigureAsImage(ff,runParams,'UVmapping',sprintf('RMSE'),1);
    end
end
%%
if fixRgbThermal && data.rgb.isValid
    crnrsData = nan(numel(hum),size(data.framesData(1).ptsWithZ,1),2);
    for iTemps = 1:numel(hum)
        crnrsData(iTemps,:,:) = data.framesData(iTemps).ptsWithZ(:,end-1:end);
    end
    [fixedCrnrsData,isFixed] = Calibration.thermal.fixRgbWithThermalCoeffs(crnrsData,hum,data.rgb,data.rgb.rgbCalTemp,fprintff);
    if isFixed
        framesDataFixed = data.framesData;
        for iTemps = 1:numel(hum)
            framesDataFixed(iTemps).ptsWithZ(:,end-1:end) = fixedCrnrsData(iTemps,:,:);
        end
        nBins = calibParams.fwTable.nRows;
        framesPerTemperatureFixed = Calibration.thermal.medianFrameByTemp(framesDataFixed,nBins,tmpBinIndices);
        uvCorrectedResults = Calibration.thermal.calcThermalUvMap(framesPerTemperatureFixed,calibParams,params);
        metrics.uvMeanRmseFixed = nanmean(uvCorrectedResults(:,1));
        metrics.uvMaxErrFixed = max(uvCorrectedResults(:,2));
        metrics.uvMaxErr95Fixed = max(uvCorrectedResults(:,3));
        metrics.uvMinErrFixed = min(uvCorrectedResults(:,4));
        if ~isempty(runParams) && isfield(runParams, 'outputFolder')
            if ~params.inValidationStage
                legends = {'UV mapping (cal)','UV mapping after Theoretical Fix(cal)'};
            else
                legends = {'UV mapping (val)','UV mapping after Theoretical Fix (val)'};
            end
            
            hold on; plot(tmpBinEdges,uvCorrectedResults(:,1));
            if isfield(data,'rgb')
                hold on;
                plot([data.rgb.rgbCalTemp,data.rgb.rgbCalTemp],[0,max(uvResults(:,1))],'k--','linewidth',2);
                legends{end+1} = 'Cal Humidity Temp';
            end
            legend(legends);
            Calibration.aux.saveFigureAsImage(ff,runParams,'UVmapping',sprintf('RMSE'),1);
        end
    else
        if ~isempty(runParams) && isfield(runParams, 'outputFolder')
            legend(legends);
            Calibration.aux.saveFigureAsImage(ff,runParams,'UVmapping',sprintf('RMSE'),1);
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cornersRtdVsIRFigure(data,runParams)
    fd = Calibration.thermal.framesDataVectors(data.framesData);
    validCB = reshape(fd.validCB,20,28);
    % extract sub-checkerboard for the purpose of choosing 2 opposite corners
    fullBoard = single(validCB);
    fullBoard(fullBoard==0) = NaN;
    [~, validRows, validCols] = CBTools.extractSubRectangleCheckerboard(fullBoard);
    validSubCB = false(size(validCB));
    validSubCB(validRows, validCols) = true;
    
    vCols = find(any(validSubCB,1));
    vRows = find(any(validSubCB,2));
    centerIdx = round([mean(vRows),mean(vCols)]) - [vRows(1),vCols(1)]+1;
    centerIdx = sub2ind([numel(vRows),numel(vCols)],centerIdx(1),centerIdx(2));
    
    rtdvalid = squeeze(fd.ptsWithZ(validSubCB,1,:));
    ptsWithZValid = squeeze(fd.ptsWithZ(validSubCB,:,:));
    idx = [1,size(rtdvalid,1),centerIdx];
    
    ff = Calibration.aux.invisibleFigure;
    plot(fd.ptsWithZ(validCB,4,1),fd.ptsWithZ(validCB,5,1),'r*') % here the full (possibly non-rectangular) checkerbord is plotted intentionally
    hold on
    plot(ptsWithZValid(idx,4,1),ptsWithZValid(idx,5,1),'bo')
    rectangle('position',[0,0,data.regs.GNRL.imgHsize,data.regs.GNRL.imgVsize],'linewidth',2);
    axis tight
    grid on
    title('Valid Corners Locations')
    legend({'Corners';'3 Corners For IR/RTD Plot '})
    axis ij
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('AlwaysValidCorners'));

    ff = Calibration.aux.invisibleFigure;
    yyaxis left
    plot(fd.ldd,rtdvalid(idx,:),'linewidth',1.5)
    xlabel('ldd degrees')
    ylabel('mm')
    yyaxis right
    plot(fd.ldd,fd.irStatMean,'linewidth',1.5)
    ylabel('IR')
    legend({'topLeft';'bottomRight';'center';'IR'})
    grid minor
    title('IR vs RTD 3 corners')
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('IR_vs_Rtd_3_corners'),1);
    
    if isfield(data,'dutyCycle2Conf')
        first15 = find(data.dutyCycle2Conf.confidence == 15,1);
        conf = data.dutyCycle2Conf.confidence(1:first15);
        dc = data.dutyCycle2Conf.dutyCycle(1:first15);
        [conf,uIds] = unique(conf);
        dc = dc(uIds);
        dcMean = interp1(conf,dc,fd.cStatMean);

        ff = Calibration.aux.invisibleFigure;
        plot(fd.ldd,dcMean);
        xlabel('ldd [deg]');
        ylabel('Duty Cycle');
        title('Mean DC(ldd)');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('ConfMeanVal'),1);

        confPtsValid = interp1(conf,dc,squeeze(fd.confPts(validCB,:,:)));
        ff = Calibration.aux.invisibleFigure;
        yyaxis left
        plot(fd.ldd,confPtsValid(idx(1),:),'*','linewidth',1.5)
        hold on
        plot(fd.ldd,confPtsValid(idx(2),:),'*','linewidth',1.5)
        plot(fd.ldd,confPtsValid(idx(3),:),'*','linewidth',1.5)
        ylim([0,1]);
        xlabel('ldd degrees')
        ylabel('DC')

        yyaxis right
        plot(fd.ldd,fd.irStatMean,'*','linewidth',1.5)
        ylabel('IR')
        legend({'topLeft';'bottomRight';'center';'IR'})

        grid minor
        title('IR vs DC 3 corners')
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('IR_vs_DC_3_corners'),1);
    end
    
end