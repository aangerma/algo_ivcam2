function [losResults,allResults,frames,dbgData] = validateLOS(hw,runParams,validationParams,fprintff)
    %VALIDATELOS Summary of this function goes here
    %   Detailed explanation goes here
    losResults = struct;
    
    
    if ~exist('validationParams','var') || isempty(validationParams)
        validationParams.numOfFrames = 100;
        validationParams.sphericalMode = 1;
    end
    
    if ~exist('fprintff','var')
        fprintff = [];
    end
    
    r=Calibration.RegState(hw);
    r.add('DIGGsphericalEn',logical(validationParams.sphericalMode));
    r.set();
    pause(0.1);
    
    params = Validation.aux.defaultMetricsParams();
    params.verbose = 0;
    
    frames = hw.getFrame(validationParams.numOfFrames,false);
    [score, allResults,dbgData] = Validation.metrics.losGridDrift(frames, params);
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
        losResults.losMaxDrift = allResults.maxDrift;
        losResults.losMeanStdX = allResults.meanStdX;
        losResults.losMeanStdY = allResults.meanStdY;
    end
    ff = Calibration.aux.invisibleFigure();
    imagesc(frames(1).i),colormap gray;
    hold on;
    quiver(dbgData.gridPoints(:,1),dbgData.gridPoints(:,2),dbgData.driftX',dbgData.driftY','r');
    hold off;
    title('Drifts');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Drifts');
    
    ff = Calibration.aux.invisibleFigure();
    imagesc(frames(1).i),colormap gray;
    hold on;
    for i=1:size(dbgData.gridPoints,1)
        draw_ellipse(dbgData.gridPoints(i,:)',reshape(dbgData.pStd(i,[1 2 2 1])*3,[2 2]),'r');
    end
    hold off;
    title('Location stability');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Location stability');
    
    
    ff = Calibration.aux.invisibleFigure();
    imshowpair(frames(end).i,frames(1).i);
    title('LOS test: Last image over first image');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','LOS test');
    if ~isempty(fprintff)
        fprintff('Max drift %2.2g\n',score);
    end
    r.reset();
end

