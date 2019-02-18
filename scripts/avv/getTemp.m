function [lddTmptr,mcTmptr,maTmptr,tSense,vSense] = getTemp()    
    hw = HWinterface();
    [lddTmptr,mcTmptr,maTmptr,tSense,vSense] = hw.getLddTemperature();
end

    