function [ metrics ] = analyzeFramesOverTemperature(data,calibParams,runParams,fprintff,inValidationStage)
% Calculate the following metrics:
% ,minEGeom,maxeGeom,meaneGeom
% stdX,stdY,p2pY,p2pX



regs = data.regs;

invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
data.framesData = data.framesData(~invalidFrames);

tempVec = [data.framesData.temp];
tempVec = [tempVec.ldd];

refTmp = regs.FRMW.dfzCalTmp;
tmpBinEdges = (calibParams.fwTable.tempBinRange(1):calibParams.fwTable.tempBinRange(2)) - 0.5;
tmpBinEdgesLong = (calibParams.fwTable.tempBinRange(1):calibParams.fwTable.tempBinRange(2)+10) - 0.5;
refBinIndex = 1+floor((refTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
tmpBinIndices = 1+floor((tempVec-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));


framesPerTemperature = Calibration.thermal.medianFrameByTemp(data.framesData,tmpBinEdgesLong,tmpBinIndices);

if inValidationStage
   calibrationDataFn = fullfile(runParams.outputFolder,'data.mat'); 
   if exist(calibrationDataFn, 'file') == 2
       calibData = load(calibrationDataFn);
       calibData = calibData.data;
       framesPerTemperature = cat(4,framesPerTemperature,calibData.processed.framesPerTemperature);
   end
   
end


Calibration.thermal.plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdgesLong,refBinIndex,runParams,inValidationStage);

validTemps = ~all(all(isnan(framesPerTemperature(:,:,:,1)),3),2);

validFramesData = framesPerTemperature(validTemps,:,:,1);
validCBPoints = all(all(~isnan(validFramesData),3),1);
validFramesData = validFramesData(:,validCBPoints,:);
stdVals = mean(std(validFramesData));
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
else
    validCBPoints = reshape(validCBPoints,20,28);
    validRows = find(any(~isnan(validCBPoints),2));
    validCols = find(any(~isnan(validCBPoints),1));
    cbGridSz = [numel(validRows),numel(validCols)];
end
eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesData(i,:,end-2:end)), cbGridSz, calibParams.gnrl.cbSquareSz);
eGeomOverTemp = nan(1,numel(tmpBinEdgesLong));
eGeomOverTemp(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);




metrics.meanEGeom = nanmean(eGeomOverTemp);
metrics.maxEGeom = max(eGeomOverTemp);
metrics.minEGeom = min(eGeomOverTemp);

legends = {'Post Fix (val)';'Pre Fix (cal)'};
if size(framesPerTemperature,4)>1 % Compare validation to calibration
    validFramesCalData = framesPerTemperature(validTemps,:,:,2);
    eGeoms = @(i) Validation.aux.gridError(squeeze(validFramesCalData(i,:,end-2:end)), cbGridSz, calibParams.gnrl.cbSquareSz);
    eGeomOverTempCal = nan(1,numel(tmpBinEdgesLong));
    eGeomOverTempCal(validTemps) = arrayfun(@(i) eGeoms(i), 1:nTemps);
    eGeomOverTemp = [eGeomOverTemp;eGeomOverTempCal];
    
else
    legends = legends(2-inValidationStage);
end
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdgesLong,eGeomOverTemp)
    title('Heating Stage EGeom'); grid on;xlabel('degrees');ylabel('eGeom [mm]');legend(legends);
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('EGeomOverTemp'),1);
end

end

