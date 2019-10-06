function [roiRegs,results,fovData] = ROI_Calib_Calc_int(im, calibParams, regs,runParams,results)
    
    [roiRegs,roiResults] = Calibration.roi.calibROIFromZ(im,regs,calibParams,runParams);
    fovData = Calibration.validation.calculateFOVFromZ(im,regs,calibParams,runParams);
    results = Validation.aux.mergeResultStruct(results, roiResults);


%     results.upDownFovDiff = sum(abs(fovData.laser.minMaxAngYup-fovData.laser.minMaxAngYdown));
end
