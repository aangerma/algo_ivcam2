function [fixedCrnrsData] = fixRgbWithThermalCoeffs(crnrsData,temps,rgbThermalData,rgbCalibTemp,fprintff)
nBins = size(rgbThermalData.thermalTable,1);
% temps = [data.framesData.temp];
% temps = [temps.ldd];
fixedCrnrsData = crnrsData;
tempRange = [rgbThermalData.minTemp rgbThermalData.referenceTemp];
ixInRange = temps >= tempRange(1) & temps <= tempRange(2);
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
iForInverseTrans = find(abs(rgbCalibTemp-tempGrid) <= tempStep/2);
transMatFromCalibTemp =  [rgbThermalData.thermalTable(iForInverseTrans,1), -rgbThermalData.thermalTable(iForInverseTrans,2),0;...
    rgbThermalData.thermalTable(iForInverseTrans,2), rgbThermalData.thermalTable(iForInverseTrans,1), 0;...
    rgbThermalData.thermalTable(iForInverseTrans,3), rgbThermalData.thermalTable(iForInverseTrans,4), 1];
% transMatFromCalibTemp =  [rgbThermalData.thermalTable(iForInverseTrans,1), 0,0;...
%              0, 1, 0;...
%              rgbThermalData.thermalTable(iForInverseTrans,3), 0, 1];

for ixTempGroup = 1:numel(ixPerTemp)-1 %Running on nBins (29) temperature groups
    frameIx = ixPerTemp{ixTempGroup};
    if isempty(frameIx)
        continue;
    end
    transMat = [rgbThermalData.thermalTable(ixTempGroup,1), -rgbThermalData.thermalTable(ixTempGroup,2),0;...
        rgbThermalData.thermalTable(ixTempGroup,2), rgbThermalData.thermalTable(ixTempGroup,1), 0;...
        rgbThermalData.thermalTable(ixTempGroup,3), rgbThermalData.thermalTable(ixTempGroup,4),1];
    %  transMat = [rgbThermalData.thermalTable(ixTempGroup,1), 0,0;...
    %                 0, 1, 0;...
    %                 rgbThermalData.thermalTable(ixTempGroup,3), 0,1];
    for ixFrameInTempGroup = 1:numel(ixPerTemp{ixTempGroup}) %Running on the corners that belong to the current bin (temperatue range)
        xyCurrentFrame = squeeze(crnrsDataInRng(frameIx(ixFrameInTempGroup),:,:));
        fixedPtsInRefTemp = [xyCurrentFrame,ones(size(xyCurrentFrame,1),1)]*transMat; %All corners in current bin are transformed with the same transformation to the thermal reference temperature
        xyCurrentFrame = fixedPtsInRefTemp(:,1:2)./fixedPtsInRefTemp(:,3);
        fixedPtsInRefTemp = [xyCurrentFrame,ones(size(xyCurrentFrame,1),1)]/transMatFromCalibTemp; %Now inverse to the RGB calibration temperature
        crnrsDataInRng(frameIx(ixFrameInTempGroup),:,:) = fixedPtsInRefTemp(:,1:2)./fixedPtsInRefTemp(:,3);
    end
end
%%
fixedCrnrsData(ixInRange,:,:) = crnrsDataInRng;

end

% crnrsData = nan(numel(temps),size(data.framesData(1).ptsWithZ,1),2);
% for iTemps = 1:numel(temps)
%     crnrsData(iTemps,:,:) = data.framesData(iTemps).ptsWithZ(:,6:7);
% end