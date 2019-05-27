function [ roiResults,frames,mr ] = validateROI( hw,calibParams,fprintff )
    frames = hw.getFrame(10);
    [roiResults,mr] = Calibration.validation.ROICalc(frames,calibParams,fprintff);
end
