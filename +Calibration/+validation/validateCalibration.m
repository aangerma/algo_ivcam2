function validateCalibration(runParams,calibParams,fprintff)
    if runParams.validation
        fprintff('[-] Validation...\n');
        waitfor(msgbox('Please disconnect and reconnect the unit. Press ok when done.'));
        hw = HWinterface();
        fprintff('opening stream...');
        hw.getFrame();
        fprintff('Done(%ds)\n',round(toc(t)));
        
        
        Calibration.validation.validateDSM(hw,fprintff);
        Calibration.validation.validateDelays(hw,calibParams,fprintff);
        Calibration.validation.validateDFZ(hw,fprintff);
        Calibration.validation.validateROI(hw,calibParams,fprintff);
        
                
        
        frame = hw.getFrame(10);
        [~, results] = Validation.metrics.gridEdgeSharp(frame, []);
        fprintff('%s: %2.2g\n','horizSharpnessMean',results.horizMean);
        fprintff('%s: %2.2g\n','vertSharpnessMean',results.vertMean);
        
        fprintff('Validation finished.\n');
    end

end
