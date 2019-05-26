function [  ] = plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdges,refBinIndex,runParams,inValidationStage)

% ptsWithZ = [rtd,angx,angy,pts,verts];

% Plots mean X/Y/RTD offset in respect to calib temp
% Plots RMS X/Y/RTD diff in respect to calib temp
nCollection = size(framesPerTemperature,4);
meanRtdXYOffset = nan(size(framesPerTemperature,1),3,nCollection);
rmsRtdXYOffset = nan(size(framesPerTemperature,1),3,nCollection);
maxRtdXYOffset = nan(size(framesPerTemperature,1),3,nCollection);

refFrame = squeeze(framesPerTemperature(refBinIndex,:,:,:));
for i = 1:size(framesPerTemperature,1)
    currFrame = squeeze(framesPerTemperature(i,:,:,:));
    if all(all(isnan(currFrame(:,:,1))))
       continue;
    end
    diff = currFrame - refFrame;
    RtdXY = diff(:,[1,4,5],:);
    meanRtdXYOffset(i,:,:) = nanmean( RtdXY );
    validPts = ~any(isnan(diff(:,:,1)),2);
    rmsRtdXYOffset(i,:,:) =  rms(RtdXY(validPts,:,:));
    maxOffset = max(abs(RtdXY(validPts,:,:)));
    if ~isempty(maxOffset)
        maxRtdXYOffset(i,:,:) = maxOffset;
    end
    
end


sq = @squeeze;
if ~isempty(runParams)
    % RTD error
    if ~inValidationStage
        legends = {'Pre Fix (cal)';'Theoretical Fix (val)'};
    else
        legends = {'Post Fix (val)';'Pre Fix (cal)';'Theoretical Fix (val)'};
    end
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
            

end

end

