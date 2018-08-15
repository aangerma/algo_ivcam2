function validateCalibration(runParams,calibParams,fprintff)
    if runParams.validation
        fprintff('[-] Validation...\n');
        hw = HWinterface();
        fprintff('opening stream...');
        frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
        fprintff('Done.\n');
        
        
        
        Calibration.validation.validateDelays(hw,calibParams,fprintff);
        Calibration.validation.validateDFZ(hw,frame,fprintff);
        Calibration.validation.validateROI(hw,calibParams,fprintff);
        [~, results] = Validation.metrics.gridEdgeSharp(frame, []);
        fprintff('%s: %2.2g\n','horizSharpnessMean',results.horizMean);
        fprintff('%s: %2.2g\n','vertSharpnessMean',results.vertMean);
        Calibration.validation.validateDSM(hw,fprintff);
        fprintff('Validation finished.\n');
    end

end
