function [losResults,allResults,dbgData] = LOSCalc(frames,runParams,expectedGridSize,fprintff)
    params = Validation.aux.defaultMetricsParams();
    params.verbose = 0;
    params.expectedGridSize = expectedGridSize;
    params.calibrationTargetIV2 = 1;
    params.target.target = 'checkerboard_Iv2A1';
    [score, allResults,dbgData] = Validation.metrics.losGridStability(frames, params);
    if isnan(score) % Failed to perform the metric
        if ~isempty(fprintff)
            fprintff('Max drift - Didn''t detect checkerboard.\n');
        end
        ff = Calibration.aux.invisibleFigure();
        imagesc(frames(1).i),colormap gray;
        title('Max Drift Input Image IR');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Max_Drift_Input');
        return
    else
        losResults.losMaxP2p = allResults.p2pMaxTS;
        losResults.losMeanStdX = allResults.pStdXTSMean;
        losResults.losMeanStdY = allResults.pStdYTSMean;
    end
%     ff = Calibration.aux.invisibleFigure();
%     imagesc(frames(1).i),colormap gray;
%     hold on;
%     quiver(dbgData.gridPoints(:,1),dbgData.gridPoints(:,2),dbgData.driftX',dbgData.driftY','r');
%     hold off;
%     title('Drifts');
%     Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Drifts');
    
%     ff = Calibration.aux.invisibleFigure();
%     imagesc(frames(1).i),colormap gray;
%     hold on;
%     for i=1:size(dbgData.gridPoints,1)
%         draw_ellipse(dbgData.gridPoints(i,:)',reshape(dbgData.pStd(i,[1 2 2 1])*3,[2 2]),'r');
%     end
%     hold off;
%     title('Location stability');
%     Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Location stability');
    
    
    ff = Calibration.aux.invisibleFigure();
    imshowpair(frames(end).i,frames(1).i);
    title('LOS test: Last image over first image');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','LOS test');
end
