for i = -4100 
    Calibration.dataDelay.setAbsDelay(hw, absFast+i,absSlow+i);
    f = hw.getFrame();
    tabplot;
    imagesc(f.i(:,200:400));
end