function [data ] = analyzeFramesOverTemperature(data, calibParams,runParams,fprintff,inValidationStage)
% Calculate the following metrics:
% ,minEGeom,maxeGeom,meaneGeom
% stdX,stdY,p2pY,p2pX

tmps = [data.framesData.temp];
ldds = [tmps.ldd];
data.dfzRefTmp = max(ldds);

invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
data.framesData = data.framesData(~invalidFrames);

validFrames = arrayfun(@(x) Calibration.thermal.validFrame(x.ptsWithZ,calibParams), data.framesData);
data.framesData = data.framesData(validFrames);


if ~isempty(runParams)
    cornersRtdVsIRFigure(data,runParams);
    
end

tempVec = [data.framesData.temp];
tempVec = [tempVec.ldd];

nBins = calibParams.fwTable.nRows;
dLdd = (calibParams.fwTable.tempBinRange(2) - calibParams.fwTable.tempBinRange(1))/(nBins-1);
tmpBinEdges = linspace(calibParams.fwTable.tempBinRange(1),calibParams.fwTable.tempBinRange(2),nBins) - dLdd*0.5;
refBinIndex = 1+floor((data.dfzRefTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
tmpBinIndices = 1+floor((tempVec-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));


framesPerTemperature = Calibration.thermal.medianFrameByTemp(data.framesData,nBins,tmpBinIndices);

data.processed.framesPerTemperature = framesPerTemperature;

if isfield(calibParams.gnrl, 'rgb') && isfield(calibParams.gnrl.rgb, 'doStream') && calibParams.gnrl.rgb.doStream
    plotRGB = 1;
else
    plotRGB = 0;
end

Calibration.thermal.plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdges,refBinIndex,runParams,inValidationStage,plotRGB);

validTemps = ~all(any(isnan(framesPerTemperature(:,:,:,1)),3),2);
assert(sum(validTemps)>1, 'Thermal sweep occupies less than 2 bins - this is incompatible with code later on')

validFramesData = framesPerTemperature(validTemps,:,:,1);
% validCBPoints = all(all(~isnan(validFramesData),3),1);
% validFramesData = validFramesData(:,validCBPoints,:);
isDataWithXYZ = (size(validFramesData,3)>=8); % hack for dealing with missing XYZ data (pointsWithZ(6:8)) in ATC
stdVals = nanmean(nanstd(validFramesData));


metrics = Calibration.thermal.calcThermalScores(data,calibParams,runParams.calibRes);
%%
if plotRGB && isfield(data,'camerasParams')
    [metrics] = analyzeNplotRgb(data,framesPerTemperature,tmpBinEdges,tmpBinIndices,ldds,calibParams,runParams,metrics,inValidationStage,fprintff);
    %%
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
    validFramesData = validFramesData(:,validCBPoints(:),:);
end
if isDataWithXYZ % hack for dealing with missing XYZ data in validFramesData (pointsWithZ(6:8)) in ATC
    eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesData(i,:,6:8)), cbGridSz, calibParams.gnrl.cbSquareSz);
    eGeomOverTemp = nan(1,numel(tmpBinEdges));
    eGeomOverTemp(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);
    
    metrics.meanEGeom = nanmean(eGeomOverTemp);
    metrics.maxEGeom = max(eGeomOverTemp);
    metrics.minEGeom = min(eGeomOverTemp);
    
    if inValidationStage % Compare calibration to theoretical Fix
        legends = {'Post Fix (val)'};
    else
        legends = {'Pre Fix (cal)'};
    end
    
    if ~isempty(runParams)
        ff = Calibration.aux.invisibleFigure;
        plot(tmpBinEdges,eGeomOverTemp)
        title('Heating Stage EGeom'); grid on;xlabel('degrees');ylabel('eGeom [mm]');legend(legends);
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('EGeomOverTemp'),1);
    end
end
data.results = metrics;
end

function [params] = prepareParams4UvMap(camerasParams)
params.depthRes = camerasParams.depthRes;
params.rgbPmat = camerasParams.rgbPmat;
params.Krgb = camerasParams.Krgb;
params.rgbDistort = camerasParams.rgbDistort;
end

function [metrics] = analyzeNplotRgb(data,framesPerTemperature,tmpBinEdges,tmpBinIndices,ldds,calibParams,runParams,metrics,inValidationStage,fprintff)
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
if ~isempty(runParams)
    if ~params.inValidationStage
        legends = {'Pre Fix (cal)'};
    else
        legends = {'Post Fix (val)'};
    end
    
    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,uvResults(:,1));
    
    title('UV mapping RMSE vs Temperature'); grid on;xlabel('degrees');ylabel('UV RMSE [rgb pixels]'); axis square;
    if ~fixRgbThermal || ~sum(data.rgb.thermalTable(:))
        if isfield(data,'rgb')
            hold on;
            plot([data.rgb.rgbCalTemp,data.rgb.rgbCalTemp],[0,max(uvResults(:,1))],'k--','linewidth',2);
            legends{end+1} = 'Cal Ldd Temp';
        end
        legend(legends);
        Calibration.aux.saveFigureAsImage(ff,runParams,'UVmapping',sprintf('RMSE'),1);
    end
end
%%
if fixRgbThermal && sum(data.rgb.thermalTable(:))
    crnrsData = nan(numel(ldds),size(data.framesData(1).ptsWithZ,1),2);
    for iTemps = 1:numel(ldds)
        crnrsData(iTemps,:,:) = data.framesData(iTemps).ptsWithZ(:,end-1:end);
    end
    [fixedCrnrsData,isFixed] = Calibration.thermal.fixRgbWithThermalCoeffs(crnrsData,ldds,data.rgb,data.rgb.rgbCalTemp,fprintff);
    if isFixed
        framesDataFixed = data.framesData;
        for iTemps = 1:numel(ldds)
            framesDataFixed(iTemps).ptsWithZ(:,end-1:end) = fixedCrnrsData(iTemps,:,:);
        end
        nBins = calibParams.fwTable.nRows;
        framesPerTemperatureFixed = Calibration.thermal.medianFrameByTemp(framesDataFixed,nBins,tmpBinIndices);
        uvCorrectedResults = Calibration.thermal.calcThermalUvMap(framesPerTemperatureFixed,calibParams,params);
        metrics.uvMeanRmseFixed = nanmean(uvCorrectedResults(:,1));
        metrics.uvMaxErrFixed = max(uvCorrectedResults(:,2));
        metrics.uvMaxErr95Fixed = max(uvCorrectedResults(:,3));
        metrics.uvMinErrFixed = min(uvCorrectedResults(:,4));
        if ~isempty(runParams)
            if ~params.inValidationStage
                legends = {'UV mapping (cal)','UV mapping after Theoretical Fix(cal)'};
            else
                legends = {'UV mapping (val)','UV mapping after Theoretical Fix (val)'};
            end
            
            hold on; plot(tmpBinEdges,uvCorrectedResults(:,1));
            if isfield(data,'rgb')
                hold on;
                plot([data.rgb.rgbCalTemp,data.rgb.rgbCalTemp],[0,max(uvResults(:,1))],'k--','linewidth',2);
                legends{end+1} = 'Cal Ldd Temp';
            end
            legend(legends);
            Calibration.aux.saveFigureAsImage(ff,runParams,'UVmapping',sprintf('RMSE'),1);
        end
    else
        if ~isempty(runParams)
            legend(legends);
            Calibration.aux.saveFigureAsImage(ff,runParams,'UVmapping',sprintf('RMSE'),1);
        end
    end
end
end
function cornersRtdVsIRFigure(data,runParams)
    fd = Calibration.thermal.framesDataVectors(data.framesData);
    validCB = reshape(fd.validCB,20,28);
    vCols = find(any(validCB,1));
    vRows = find(any(validCB,2));
    centerIdx = round([mean(vRows),mean(vCols)]) - [vRows(1),vCols(1)]+1;
    centerIdx = sub2ind([numel(vRows),numel(vCols)],centerIdx(1),centerIdx(2));
    
    rtdvalid = squeeze(fd.ptsWithZ(validCB,1,:));
    ptsWithZValid = squeeze(fd.ptsWithZ(validCB,:,:));
    idx = [1,size(rtdvalid,1),centerIdx];
    
    ff = Calibration.aux.invisibleFigure;
    plot(fd.ptsWithZ(validCB,4,1),fd.ptsWithZ(validCB,5,1),'r*')
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