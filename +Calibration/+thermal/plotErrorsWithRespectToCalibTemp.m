function [  ] = plotErrorsWithRespectToCalibTemp(framesPerTemperature,tmpBinEdges,refBinIndex,runParams)

% ptsWithZ = [rtd,angx,angy,pts,verts];

% Plots mean X/Y/RTD offset in respect to calib temp
% Plots RMS X/Y/RTD diff in respect to calib temp

meanRtdXYOffset = nan(size(framesPerTemperature,1),3);
rmsRtdXYOffset = nan(size(framesPerTemperature,1),3);
maxRtdXYOffset = nan(size(framesPerTemperature,1),3);

refFrame = squeeze(framesPerTemperature(refBinIndex,:,:));
for i = 1:size(framesPerTemperature,1)
    currFrame = squeeze(framesPerTemperature(i,:,:));
    if all(isnan(currFrame))
       continue;
    end
    diff = currFrame - refFrame;
    RtdXY = diff(:,[1,4,5]);
    meanRtdXYOffset(i,:) = nanmean( RtdXY );
    validPts = ~any(isnan(diff),2);
    rmsRtdXYOffset(i,:) =  rms(RtdXY(validPts,:));
    maxRtdXYOffset(i,:) = max(abs(RtdXY(validPts,:)));
end



if ~isempty(runParams)
    % Mean error
    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,meanRtdXYOffset(:,1))
    title('Heating Stage Mean Rtd Offset'); grid on;xlabel('degrees');ylabel('RTD [mm]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanRtdOffset'),1);

    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,meanRtdXYOffset(:,2))
    title('Heating Stage Mean X Offset'); grid on;xlabel('degrees');ylabel('X diff [pixels]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanXOffset'),1);

    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,meanRtdXYOffset(:,3))
    title('Heating Stage Mean Y Offset'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanYOffset'),1);
    % RMS Error
    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,rmsRtdXYOffset(:,1))
    title('Heating Stage Rtd RMS'); grid on;xlabel('degrees');ylabel('RTD [mm]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('RMS_Rtd'),1);

    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,rmsRtdXYOffset(:,2))
    title('Heating Stage X RMS'); grid on;xlabel('degrees');ylabel('X diff [pixels]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('RMS_X'),1);

    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,rmsRtdXYOffset(:,3))
    title('Heating Stage Y RMS'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('RMS_Y'),1);

    % RMS Error
    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,maxRtdXYOffset(:,1))
    title('Heating Stage Rtd Max Diff'); grid on;xlabel('degrees');ylabel('RTD [mm]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Max_Diff_Rtd'),1);

    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,maxRtdXYOffset(:,2))
    title('Heating Stage X Max Diff'); grid on;xlabel('degrees');ylabel('X diff [pixels]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Max_Diff_X'),1);

    ff = Calibration.aux.invisibleFigure;
    plot(tmpBinEdges,maxRtdXYOffset(:,3))
    title('Heating Stage Y Max Diff'); grid on;xlabel('degrees');ylabel('Y diff [pixels]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Max_Diff_Y'),1);
            

end

end

