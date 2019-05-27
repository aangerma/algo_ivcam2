function [lddTmptr,mcTmptr,maTmptr,apdTemp] = getTemp()    
    hw = HWinterface();
    [lddTmptr,mcTmptr,maTmptr,apdTemp] = hw.getLddTemperature();
end

    