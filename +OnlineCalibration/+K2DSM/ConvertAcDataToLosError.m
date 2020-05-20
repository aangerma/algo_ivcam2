function [losScaling, losShift] = ConvertAcDataToLosError(dsmRegs, acDataIn)
    
    switch acDataIn.flags(1) % model flag
        case 0 % none
            losScaling = ones(2,1);
            losShift = zeros(2,1);
        case 1 % AOT
            losScaling = 1./[acDataIn.hFactor; acDataIn.vFactor];
            losShift = -[acDataIn.hOffset; acDataIn.vOffset].*losScaling;
        case 2 % TOA
            losScaling = 1./[acDataIn.hFactor; acDataIn.vFactor];
            dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acDataIn, dsmRegs, 'inverse'); % the one used for assessing LOS error
            losShift = -[acDataIn.hOffset/dsmRegsOrig.dsmXscale; acDataIn.vOffset/dsmRegsOrig.dsmYscale]-[dsmRegsOrig.dsmXoffset; dsmRegsOrig.dsmYoffset].*(1-losScaling);
        otherwise
            error('Only {0,1,2} are supported as values for modelFlag');
    end
    
end