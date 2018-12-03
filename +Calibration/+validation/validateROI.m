function [ roiResults  ] = validateROI( hw,calibParams,fprintff )
    roiResults = [];
    d = hw.getFrame(10);
    roiRegsVal = Calibration.roi.runROICalib(d,calibParams);
    mr = roiRegsVal.FRMW;
    valSumMargins = double(mr.marginL + mr.marginR + mr.marginT + mr.marginB);
    roiResults.roiHorizontalLoss = mr.marginL + mr.marginR;
    roiResults.roiVerticalLoss = mr.marginT + mr.marginB;
    
    if (valSumMargins ~= 0)
        fprintff('ROI: Invalid pixels exists at edges.[%d,%d,%d,%d].\n',mr.marginL, mr.marginR, mr.marginT, mr.marginB);
    else
        fprintff('ROI: All pixels are valid.\n');
    end

end

