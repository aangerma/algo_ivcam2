function [fixedCrnrsData,isFixed] = fixRgbWithThermalCoeffs(crnrsData,temps,rgbThermalData,fprintff)
nBins = size(rgbThermalData.thermalTable,1);
rgbCalTemp = rgbThermalData.rgbCalTemp;
if rgbThermalData.referenceTemp ~= rgbThermalData.rgbCalTemp
    [rgbThermalData] = Calibration.rgb.adjustRgbThermal2NewRefTemp(rgbThermalData,rgbCalTemp,fprintff);
    rgbThermalData.rgbCalTemp = rgbCalTemp;
end
fixedCrnrsData = crnrsData;
tempRange = [rgbThermalData.minTemp rgbThermalData.maxTemp];
ixInRange = temps >= tempRange(1) & temps <= tempRange(2);
isFixed = 0;
if ~sum(ixInRange)
    fprintff('No frame data was found in the thermal RGB table range: [%2.2f,%2.2f]',tempRange(1),tempRange(2));
    return;
end
tempsInRng = temps(ixInRange);
crnrsDataInRng = crnrsData(ixInRange,:,:);
tempGridEdges = linspace(tempRange(1),tempRange(2),nBins+2);
tempStep = tempGridEdges(2)-tempGridEdges(1);
tempGrid = tempStep/2 + tempGridEdges(1:end-1);
ixPerTemp = cell(size(tempGrid));

for k = 1:numel(tempGrid)-1
    ixPerTemp{k} = find(abs(tempsInRng-tempGrid(k)) <= tempStep/2);
end
% referenceTempMedian = squeeze(median(crnrsDataInRng(ixPerTemp{end},:,:),1));
%%

for ixTempGroup = 1:numel(ixPerTemp)-1 %Running on nBins (29) temperature groups
    frameIx = ixPerTemp{ixTempGroup};
    if isempty(frameIx)
        continue;
    end
    transMat = [rgbThermalData.thermalTable(ixTempGroup,1), -rgbThermalData.thermalTable(ixTempGroup,2),0;...
        rgbThermalData.thermalTable(ixTempGroup,2), rgbThermalData.thermalTable(ixTempGroup,1), 0;...
        rgbThermalData.thermalTable(ixTempGroup,3), rgbThermalData.thermalTable(ixTempGroup,4),1];
    for ixFrameInTempGroup = 1:numel(ixPerTemp{ixTempGroup}) %Running on the corners that belong to the current bin (temperature range)
        xyCurrentFrame = squeeze(crnrsDataInRng(frameIx(ixFrameInTempGroup),:,:));
        fixedPtsInRefTemp = [xyCurrentFrame,ones(size(xyCurrentFrame,1),1)]*transMat; %All corners in current bin are transformed with the same transformation to the thermal reference temperature
        crnrsDataInRng(frameIx(ixFrameInTempGroup),:,:) = fixedPtsInRefTemp(:,1:2)./fixedPtsInRefTemp(:,3);
    end
end
%%
fixedCrnrsData(ixInRange,:,:) = crnrsDataInRng;
isFixed = 1;
end

% crnrsData = nan(numel(temps),size(data.framesData(1).ptsWithZ,1),2);
% for iTemps = 1:numel(temps)
%     crnrsData(iTemps,:,:) = data.framesData(iTemps).ptsWithZ(:,6:7);
% end