function [agingRegs,results] = RtdOverAging_Calib_Calc_int(im, calibParams, runParams, res, z2mm, vddSamples)      
 
    sampledVoltages = mean(cellfun(@vdd12BitToVoltage,vddSamples),2);
    sampledVdd12Bit = arrayfun(@voltageTo12Bits,sampledVoltages,'UniformOutput',0);
   
    params = Validation.aux.defaultMetricsParams();
    params.mask.rectROI.flag = true;
    params.mask.rectROI.allMargins = calibParams.aging.roi;
    sz = size(im);
    mask = Validation.aux.getMask(params,'imageSize',sz);
    for i = 1:numel(im)
        diffDist(i) = mean(single(im(i).z(mask))/z2mm - single(im(1).z(mask))/z2mm)*2;
    end
    
    
    agingRegs.FRMW.vddVoltValues = uint16(hex2dec(sampledVdd12Bit))';
    agingRegs.FRMW.vdd2RtdDiff = int16(diffDist(2));
    agingRegs.FRMW.vdd3RtdDiff = int16(diffDist(3));
    agingRegs.FRMW.vdd4RtdDiff = int16(diffDist(4));
    
    
    results.vddVoltageRange = max(sampledVoltages) - min(sampledVoltages);
    results.vddDistanceRange = max(diffDist) - min(diffDist);
    

    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure();
        plot(sampledVoltages,diffDist);title('Range Over Vdd'); ylabel('mm'); xlabel('vdd voltage');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Aging','RangeOverVdd',1); 
    end
end

function volt = vdd12BitToVoltage(vdd12Bit)
    volt = (hex2dec(vdd12Bit(end-2:end))+1157.2)/1865.8;

end
function vdd12Bit = voltageTo12Bits(volt)
    vdd12Bit = dec2hex(uint32(volt*1865.8-1157.2));
end