function [data ] = analyzeFramesOverTemperature(data,dataFixed, calibParams,runParams,fprintff,inValidationStage)
% Calculate the following metrics:
% ,minEGeom,maxeGeom,meaneGeom
% stdX,stdY,p2pY,p2pX

if inValidationStage
    data.dfzRefTmp = data.regs.FRMW.dfzCalTmp;
end

invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
data.framesData = data.framesData(~invalidFrames);

validFrames = arrayfun(@(j) Calibration.thermal.validFrame(data.framesData(j).ptsWithZ,calibParams),1:numel(data.framesData));
data.framesData = data.framesData(validFrames);


tempVec = [data.framesData.temp];
tempVec = [tempVec.ldd];


tmpBinEdges = (calibParams.fwTable.tempBinRange(1):calibParams.fwTable.tempBinRange(2)) - 0.5;
refBinIndex = 1+floor((data.dfzRefTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
tmpBinIndices = 1+floor((tempVec-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));


framesPerTemperature = Calibration.thermal.medianFrameByTemp(data.framesData,48,tmpBinIndices);
if inValidationStage
%    calibrationDataFn = fullfile(runParams.outputFolder,'data.mat'); 
%    if exist(calibrationDataFn, 'file') == 2
%        calibData = load(calibrationDataFn);
%        calibData = calibData.data;
%        framesPerTemperature = cat(4,framesPerTemperature,calibData.processed.framesPerTemperature);
%        data.dfzRefTmp = calibData.dfzRefTmp;
%        refBinIndex = 1+floor((data.dfzRefTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
%    end
   
else
   framesPerTemperatureFixed = Calibration.thermal.medianFrameByTemp(dataFixed.framesData,data.tableResults.angx.nBins,tmpBinIndices);
   framesPerTemperature = cat(4,framesPerTemperature,framesPerTemperatureFixed);
end
data.processed.framesPerTemperature = framesPerTemperature;

Calibration.thermal.plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdges,refBinIndex,runParams,inValidationStage);

validTemps = ~all(any(isnan(framesPerTemperature(:,:,:,1)),3),2);

validFramesData = framesPerTemperature(validTemps,:,:,1);
% validCBPoints = all(all(~isnan(validFramesData),3),1);
% validFramesData = validFramesData(:,validCBPoints,:);
stdVals = nanmean(nanstd(validFramesData));

metrics = Calibration.thermal.calcThermalScores(data,calibParams.fwTable.tempBinRange);

metrics.stdRtd = stdVals(1);
metrics.stdXim = stdVals(4);
metrics.stdYim = stdVals(5);
metrics.stdXmm = stdVals(6);
metrics.stdYmm = stdVals(7);
metrics.stdZmm = stdVals(8);

maxP2pVals = max(max(validFramesData,[],1)-min(validFramesData,[],1));
metrics.p2pRtd = maxP2pVals(1);
metrics.p2pXim = maxP2pVals(4);
metrics.p2pYim = maxP2pVals(5);
metrics.p2pXmm = maxP2pVals(6);
metrics.p2pYmm = maxP2pVals(7);
metrics.p2pZmm = maxP2pVals(8);

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
eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesData(i,:,end-2:end)), cbGridSz, calibParams.gnrl.cbSquareSz);
eGeomOverTemp = nan(1,numel(tmpBinEdges));
eGeomOverTemp(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);


metrics.meanEGeom = nanmean(eGeomOverTemp);
metrics.maxEGeom = max(eGeomOverTemp);
metrics.minEGeom = min(eGeomOverTemp);






if size(framesPerTemperature,4) == 2 % Compare calibration to theoretical Fix
    legends = {'Pre Fix (cal)';'Theoretical Fix (cal)'};
    validFramesCalData = framesPerTemperature(validTemps,:,:,2);
    eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesCalData(i,validCBPoints(:),end-2:end)), cbGridSz, calibParams.gnrl.cbSquareSz);
    eGeomOverTempCal = nan(1,numel(tmpBinEdges));
    eGeomOverTempCal(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);
    eGeomOverTemp = [eGeomOverTemp;eGeomOverTempCal];
    
elseif size(framesPerTemperature,4) == 3 % Compare calibration to theoretical Fix
    legends = {'Post Fix (val)';'Pre Fix (cal)';'Theoretical Fix (cal)'};
    validFramesCalData = framesPerTemperature(validTemps,:,:,2);
    eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesCalData(i,validCBPoints(:),end-2:end)), cbGridSz, calibParams.gnrl.cbSquareSz);
    eGeomOverTempCal = nan(1,numel(tmpBinEdges));
    eGeomOverTempCal(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);
    
    validFramesCalDataTheory = framesPerTemperature(validTemps,:,:,3);
    eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesCalDataTheory(i,validCBPoints(:),end-2:end)), cbGridSz, calibParams.gnrl.cbSquareSz);
    eGeomOverTempCalTheory = nan(1,numel(tmpBinEdges));
    eGeomOverTempCalTheory(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);
    
    eGeomOverTemp = [eGeomOverTemp;eGeomOverTempCal;eGeomOverTempCalTheory];
else
    legends = {'Post Fix (val)'};
end
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,eGeomOverTemp)
    title('Heating Stage EGeom'); grid on;xlabel('degrees');ylabel('eGeom [mm]');legend(legends);
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('EGeomOverTemp'),1);
end
data.results = metrics;
end

