function PlotMetricsVsError(metrics, err, errLabel)
    
    figure
    set(gcf, 'Position', [452, 284, 978, 519])
    
    subplot(231), hold on
    plot(err, [metrics.gid], '-')
    grid on, xlabel(errLabel), ylabel('error [mm]'), title('GID')
    
    subplot(234), hold on
    plot(err, [metrics.planeFitRms], '-');
    plot(err, [metrics.planeFitmax], '--');
    grid on, xlabel(errLabel), ylabel('error [mm]'), legend('RMS', 'max'), title('Plane fit')
    
    subplot(232), hold on
    plot(err, [metrics.lineFit2DHorzRms], '-');
    plot(err, [metrics.lineFit2DHorzMax], '--');
    grid on, xlabel(errLabel), ylabel('error [pixels]'), legend('RMS', 'max'), title('Horizontal 2D line fit')
    
    subplot(235), hold on
    plot(err, [metrics.lineFit2DVertRms], '-');
    plot(err, [metrics.lineFit2DVertMax], '--');
    grid on, xlabel(errLabel), ylabel('error [pixels]'), legend('RMS', 'max'), title('Vertical 2D line fit')
    
    subplot(233), hold on
    plot(err, [metrics.lineFit3DHorzRms], '-');
    plot(err, [metrics.lineFit3DHorzMax], '--');
    grid on, xlabel(errLabel), ylabel('error [mm]'), legend('RMS', 'max'), title('Horizontal 3D line fit')
    
    subplot(236), hold on
    plot(err, [metrics.lineFit3DVertRms], '-');
    plot(err, [metrics.lineFit3DVertMax], '--');
    grid on, xlabel(errLabel), ylabel('error [mm]'), legend('RMS', 'max'), title('Vertical 3D line fit')
    
end