function [losResults,allResults,frames] = validateLOS(hw,runParams,fprintff)
    %VALIDATELOS Summary of this function goes here
    %   Detailed explanation goes here
    losResults = [];
    r=Calibration.RegState(hw);
    r.add('DIGGsphericalEn',true    );
    r.set();
    pause(0.1);
    
    params = Validation.aux.defaultMetricsParams();
    params.verbose = 0;
    
    frames = hw.getFrame(100,false);
    [score, allResults,dbgData] = Validation.metrics.losGridDrift(frames, params);
    losResults.losMaxDrift = allResults.maxDrift;
    losResults.losMeanStdX = allResults.meanStdX;
    losResults.losMeanStdY = allResults.meanStdY;
    
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
    
    fprintff('Max drift %2.2g\n',score);
    r.reset();
end

