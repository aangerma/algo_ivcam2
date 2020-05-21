function acDataOut = ConvertLosErrorToAcData(dsmRegs, acDataIn, modelFlag, losShift, losScaling)
    
    acDataOut = acDataIn;
    acDataOut.flags = modelFlag;
    switch modelFlag(1)
        case 0 % none
            acDataOut.hFactor = 1;
            acDataOut.vFactor = 1;
            acDataOut.hOffset = 0;
            acDataOut.vOffset = 0;
        case 1 % AOT
            acDataOut.hFactor = 1/losScaling(1);
            acDataOut.vFactor = 1/losScaling(2);
            acDataOut.hOffset = -losShift(1)/losScaling(1);
            acDataOut.vOffset = -losShift(2)/losScaling(2);
        case 2 % TOA
            acDataOut.hFactor = 1/losScaling(1);
            acDataOut.vFactor = 1/losScaling(2);
            dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acDataIn, dsmRegs, 'inverse'); % the one used for assessing LOS error
            acDataOut.hOffset = -(dsmRegsOrig.dsmXoffset*(1-losScaling(1))+losShift(1))*dsmRegsOrig.dsmXscale;
            acDataOut.vOffset = -(dsmRegsOrig.dsmYoffset*(1-losScaling(2))+losShift(2))*dsmRegsOrig.dsmYscale;
        otherwise
            error('Only {0,1,2} are supported as values for modelFlag');
    end
    
end