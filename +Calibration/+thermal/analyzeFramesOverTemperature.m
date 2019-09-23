function [data ] = analyzeFramesOverTemperature(data, calibParams,runParams,fprintff,inValidationStage)
% Calculate the following metrics:
% ,minEGeom,maxeGeom,meaneGeom
% stdX,stdY,p2pY,p2pX


if inValidationStage
    tmps = [data.framesData.temp];
    ldds = [tmps.ldd];
    data.dfzRefTmp = mean(minmax(ldds));
end
invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
data.framesData = data.framesData(~invalidFrames);

validFrames = arrayfun(@(j) Calibration.thermal.validFrame(data.framesData(j).ptsWithZ,calibParams),1:numel(data.framesData));
data.framesData = data.framesData(validFrames);


tempVec = [data.framesData.temp];
tempVec = [tempVec.ldd];


tmpBinEdges = (calibParams.fwTable.tempBinRange(1):calibParams.fwTable.tempBinRes:calibParams.fwTable.tempBinRange(2)) - 0.5;
refBinIndex = 1+floor((data.dfzRefTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
tmpBinIndices = 1+floor((tempVec-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));


framesPerTemperature = Calibration.thermal.medianFrameByTemp(data.framesData,48,tmpBinIndices);

data.processed.framesPerTemperature = framesPerTemperature;

Calibration.thermal.plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdges,refBinIndex,runParams,inValidationStage);

validTemps = ~all(any(isnan(framesPerTemperature(:,:,:,1)),3),2);
assert(sum(validTemps)>1, 'Thermal sweep occupies less than 2 bins - this is incompatible with code later on')

validFramesData = framesPerTemperature(validTemps,:,:,1);
% validCBPoints = all(all(~isnan(validFramesData),3),1);
% validFramesData = validFramesData(:,validCBPoints,:);
isDataWithXYZ = (size(validFramesData,3)>=8); % hack for dealing with missing XYZ data (pointsWithZ(6:8)) in ATC
stdVals = nanmean(nanstd(validFramesData));

metrics = Calibration.thermal.calcThermalScores(data,calibParams.fwTable.tempBinRange,calibParams.fwTable.tempBinRes,runParams.calibRes);

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
    validCBPoints = all(all(~isnan(validFramesData),3),1);
    validCBPoints = reshape(validCBPoints,20,28);
    validRows = find(any((validCBPoints),2));
    validCols = find(any((validCBPoints),1));
    cbGridSz = [numel(validRows),numel(validCols)];
    validFramesData = validFramesData(:,validCBPoints(:),:);
end
if isDataWithXYZ % hack for dealing with missing XYZ data in validFramesData (pointsWithZ(6:8)) in ATC
    eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesData(i,:,end-2:end)), cbGridSz, calibParams.gnrl.cbSquareSz);
    eGeomOverTemp = nan(1,numel(tmpBinEdges));
    eGeomOverTemp(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);
    
    metrics.meanEGeom = nanmean(eGeomOverTemp);
    metrics.maxEGeom = max(eGeomOverTemp);
    metrics.minEGeom = min(eGeomOverTemp);
    
    if inValidationStage % Compare calibration to theoretical Fix
        legends = {'Post Fix (val)'};
    else
        legends = {'Pre Fix (val)'};
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

