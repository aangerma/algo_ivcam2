function validateCalibration(runParams,calibParams,fprintff)
    if runParams.validation
        fprintff('[-] Validation...\n');
        hw = HWinterface();
        hw.getFrame;
        fprintff('opening stream...');
        frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
        stream = hw.getNFrames(100);
        saveValidationFrames(frame,runParams,'');
        r=Calibration.RegState(hw);
        r.add('JFILbypass$'        ,true    );
        r.add('DIGGgammaScale', uint16([256,256]));
        r.set();
        pause(0.1);
        scanLinesFrame = hw.getFrame();
        saveValidationFrames(scanLinesFrame,runParams,'_scan_lines');
        r.reset();

        fprintff('Done.\n');
        params = Validation.aux.defaultMetricsParams();
        params.roi = 0.5;
        
        
        Calibration.validation.validateDelays(hw,calibParams,fprintff);
        Calibration.validation.validateDFZ(hw,frame,fprintff);
        Calibration.validation.validateROI(hw,calibParams,fprintff);
        Calibration.validation.validateLOS(hw,fprintff);
        [zSTD, ~] = Validation.metrics.zStd(stream, params);
        [~, results] = Validation.metrics.gridEdgeSharp(frame, []);
        fprintff('%s: %2.2g\n','zSTD',zSTD);
        fprintff('%s: %2.2g\n','horizSharpnessMean',results.horizMean);
        fprintff('%s: %2.2g\n','vertSharpnessMean',results.vertMean);
        Calibration.validation.validateDSM(hw,fprintff);
        fprintff('Validation finished.\n');
    end

end
function saveValidationFrames(frame,runParams,postFix)
    dirname = fullfile(runParams.outputFolder,'captures');
    mkdirSafe(dirname);
    
    f = fieldnames(frame);
    for i = 1:length(f)
        imfn = fullfile(dirname,strcat('validation_frame_',f{i},postFix,'.png'));
        imwrite(frame.(f{i}),imfn);
    end
    
end