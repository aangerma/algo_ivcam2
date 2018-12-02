function [results,frames] = validateLOS(hw,fprintff)
    %VALIDATELOS Summary of this function goes here
    %   Detailed explanation goes here
    
    r=Calibration.RegState(hw);
    r.add('DIGGsphericalEn',true    );
    r.set();
    pause(0.1);
    
    params = Validation.aux.defaultMetricsParams();
    params.verbose = 0;
    
    frames = hw.getNFrames(100,false);
    [score, results,dbgData] = Validation.metrics.losGridDrift(frames, params);
    
    
    fig1 = figure();
    imagesc(img),colormap gray;
    hold on;
    quiver(dbgData.gridPoints(:,1),dbgData.gridPoints(:,2),dbgData.driftX',dbgData.driftY','r');
    hold off;
    title('Drifts');
    
    fig2 = figure();
    imagesc(img),colormap gray;
    hold on;
    for i=1:size(dbgData.gridPoints,1)
        draw_ellipse(dbgData.gridPoints(i,:)',reshape(dbgData.pStd(i,[1 2 2 1])*3,[2 2]),'r');
    end
    hold off;
    title('Location stability');
    
    
    fig3 = figure();
    imshowpair(limg,img);
    title('LOS test: Last image over first image');

    
    fprintff('Max drift %2.2g',score);
    r.reset();
end

