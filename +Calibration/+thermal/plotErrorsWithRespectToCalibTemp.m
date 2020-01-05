function [  ] = plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdges,refBinIndex,runParams,inValidationStage,plotRGB)

% ptsWithZ = [rtd,angx,angy,pts,verts];

% Plots mean X/Y/RTD offset in respect to calib temp
% Plots RMS X/Y/RTD diff in respect to calib temp
%%
[meanRtdXYOffset,rmsRtdXYOffset,maxRtdXYOffset] = calcDataOffsets(framesPerTemperature,refBinIndex,[1,4,5]);
if exist('plotRGB','var') && plotRGB && size(framesPerTemperature,3)>5
    numOfRows = size(framesPerTemperature,3);
    [meanXYOffset_rgb,rmsXYOffset_rgb,maxXYOffset_rgb] = calcDataOffsets(framesPerTemperature,refBinIndex,[numOfRows-1,numOfRows]);
end
%%
sq = @squeeze;
if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    % RTD error
    if ~inValidationStage
        legends = {'Pre Fix (cal)'};
    else
        legends = {'Post Fix (val)'};
    end
    nCollection = size(framesPerTemperature,4);
    if nCollection > 1
        legends = legends(1:nCollection);
    else
        legends = legends(1);
    end
    ff = Calibration.aux.invisibleFigure;
    subplot(131);
    plot(tmpBinEdges,sq(meanRtdXYOffset(:,1,:)))
    title('Heating Stage Mean Rtd Offset'); grid on;xlabel('degrees');ylabel('RTD [mm]'); legend(legends);axis square;
    subplot(132);
    plot(tmpBinEdges,sq(rmsRtdXYOffset(:,1,:)))
    title('Heating Stage Rtd RMS'); grid on;xlabel('degrees');ylabel('RTD [mm]');legend(legends);axis square;
    subplot(133);
    plot(tmpBinEdges,sq(maxRtdXYOffset(:,1,:)))
    title('Heating Stage Rtd Max Diff'); grid on;xlabel('degrees');ylabel('RTD [mm]');legend(legends);axis square;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Rtd_Errors'),1);
    
    
    ff = Calibration.aux.invisibleFigure;
    subplot(131);
    plot(tmpBinEdges,sq(meanRtdXYOffset(:,2,:)))
    title('Heating Stage Mean X Offset'); grid on;xlabel('degrees');ylabel('X diff [pixels]');legend(legends);axis square;
    subplot(132);
    plot(tmpBinEdges,sq(rmsRtdXYOffset(:,2,:)))
    title('Heating Stage X RMS'); grid on;xlabel('degrees');ylabel('X diff [pixels]');legend(legends);axis square;
    subplot(133);
    plot(tmpBinEdges,sq(maxRtdXYOffset(:,2,:)))
    title('Heating Stage X Max Diff'); grid on;xlabel('degrees');ylabel('X diff [pixels]');legend(legends);axis square;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Xim_Errors'),1);
    
    ff = Calibration.aux.invisibleFigure;
    subplot(131);
    plot(tmpBinEdges,sq(meanRtdXYOffset(:,3,:)))
    title('Heating Stage Mean Y Offset'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');legend(legends);axis square;
    subplot(132);
    plot(tmpBinEdges,sq(rmsRtdXYOffset(:,3,:)))
    title('Heating Stage Y RMS'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');legend(legends);axis square;
    subplot(133);
    plot(tmpBinEdges,sq(maxRtdXYOffset(:,3,:)))
    title('Heating Stage Y Max Diff'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');legend(legends);axis square;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Yim_Errors'),1);
    
    
    ff = Calibration.aux.invisibleFigure;
    iWithTemps = find(~isnan(meanRtdXYOffset(:,1)));
    xIrLow = framesPerTemperature(iWithTemps(1),:,4);
    yIrLow = framesPerTemperature(iWithTemps(1),:,5);
    xIrHigh = framesPerTemperature(iWithTemps(end),:,4);
    yIrHigh = framesPerTemperature(iWithTemps(end),:,5);
    plot(xIrLow,yIrLow,'+g');
    hold on;
    plot(xIrHigh,yIrHigh,'+b');
    quiver(xIrLow,yIrLow,xIrHigh-xIrLow,yIrHigh-yIrLow,'r');
    title('IR corners movement from lowest to highest temperature');grid minor;legend('Lowest','Highest');
    [maxVal,maxIx] = max(sqrt((xIrHigh-xIrLow).^2 +(yIrHigh-yIrLow).^2));
    [minVal,minIx] = min(sqrt((xIrHigh-xIrLow).^2 +(yIrHigh-yIrLow).^2));
    text(xIrLow(maxIx),yIrLow(maxIx), sprintf('Max = %3.2f',maxVal));
    text(xIrLow(minIx),yIrLow(minIx), sprintf('Min = %3.2f',minVal));
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('IR_corners_movement'),1);
    
    
    if exist('plotRGB','var') && plotRGB && size(framesPerTemperature,3)>5
        ff = Calibration.aux.invisibleFigure;
        subplot(131);
        plot(tmpBinEdges,sq(meanXYOffset_rgb(:,1,:)))
        title('Heating Stage Mean X Offset RGB'); grid on;xlabel('degrees');ylabel('X diff [pixels]');legend(legends);axis square;
        subplot(132);
        plot(tmpBinEdges,sq(rmsXYOffset_rgb(:,1,:)))
        title('Heating Stage X RMS RGB'); grid on;xlabel('degrees');ylabel('X diff [pixels]');legend(legends);axis square;
        subplot(133);
        plot(tmpBinEdges,sq(maxXYOffset_rgb(:,1,:)))
        title('Heating Stage X Max Diff RGB'); grid on;xlabel('degrees');ylabel('X diff [pixels]');legend(legends);axis square;
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating_rgb',sprintf('Xim_Errors'),1);
        
        ff = Calibration.aux.invisibleFigure;
        subplot(131);
        plot(tmpBinEdges,sq(meanXYOffset_rgb(:,2,:)))
        title('Heating Stage Mean Y Offset RGB'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');legend(legends);axis square;
        subplot(132);
        plot(tmpBinEdges,sq(rmsXYOffset_rgb(:,2,:)))
        title('Heating Stage Y RMS RGB'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');legend(legends);axis square;
        subplot(133);
        plot(tmpBinEdges,sq(maxXYOffset_rgb(:,2,:)))
        title('Heating Stage Y Max Diff RGB'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');legend(legends);axis square;
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating_rgb',sprintf('Yim_Errors'),1);
        
        numOfRows = size(framesPerTemperature,3);
        ff = Calibration.aux.invisibleFigure;
        iWithTemps = find(~isnan(meanXYOffset_rgb(:,1)));
        xRgbLow = framesPerTemperature(iWithTemps(1),:,numOfRows-1);
        yRgbLow = framesPerTemperature(iWithTemps(1),:,numOfRows);
        xRgbHigh = framesPerTemperature(iWithTemps(end),:,numOfRows-1);
        yRgbHigh = framesPerTemperature(iWithTemps(end),:,numOfRows);
        plot(xRgbLow,yRgbLow,'+g');
        hold on;
        plot(xRgbHigh,yRgbHigh,'+b');
        quiver(xRgbLow,yRgbLow,xRgbHigh-xRgbLow,yRgbHigh-yRgbLow,'r');
        [maxVal,maxIx] = max(sqrt((xRgbHigh-xRgbLow).^2 +(yRgbHigh-yRgbLow).^2));
        [minVal,minIx] = min(sqrt((xRgbHigh-xRgbLow).^2 +(yRgbHigh-yRgbLow).^2));
        text(xRgbLow(maxIx),yRgbLow(maxIx), sprintf('Max = %3.2f',maxVal));
        text(xRgbLow(minIx),yRgbLow(minIx), sprintf('Min = %3.2f',minVal));
        title('RGB corners movement from lowest to highest temperature');grid minor;legend('Lowest','Highest');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating_rgb',sprintf('RGB_corners_movement'),1);
    end
end

end


function [meanDataOffset,rmsDataOffset,maxDataOffset] = calcDataOffsets(framesPerTemperature,refBinIndex,dataInds)
nCollection = size(framesPerTemperature,4);
meanDataOffset = nan(size(framesPerTemperature,1),numel(dataInds),nCollection);
rmsDataOffset = nan(size(framesPerTemperature,1),numel(dataInds),nCollection);
maxDataOffset = nan(size(framesPerTemperature,1),numel(dataInds),nCollection);
%%
refFrame = squeeze(framesPerTemperature(refBinIndex,:,:,:));
for i = 1:size(framesPerTemperature,1)
    currFrame = squeeze(framesPerTemperature(i,:,:,:));
    if all(all(isnan(currFrame(:,:,1))))
        continue;
    end
    diff = currFrame - refFrame;
    data = diff(:,dataInds,:);
    meanDataOffset(i,:,:) = nanmean( data );
    validPts = ~any(isnan(data(:,1)),2);
    rmsDataOffset(i,:,:) =  rms(data(validPts,:,:));
    dataValidPts = data(validPts,:,:);
    if isempty(dataValidPts)
        continue;
    end
    [maxOffset,ix] = max(abs(dataValidPts));
    ixLinear = sub2ind(size(dataValidPts), ix, 1:numel(dataInds));
    if ~isempty(maxOffset)
        maxDataOffset(i,:,:) = dataValidPts(ixLinear);
    end
end

end
