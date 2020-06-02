function [losScaling, losShift] = ConvertAcDataToLosError(dsmRegs, acDataIn)
    
    switch acDataIn.flags(1) % model flag
        case 0 % none
            losScaling = ones(2,1);
            losShift = zeros(2,1);
        case 1 % AOT
            losScaling = 1./[double(acDataIn.hFactor); double(acDataIn.vFactor)];
            losShift = -[double(acDataIn.hOffset); double(acDataIn.vOffset)].*losScaling;
        case 2 % TOA
            losScaling = 1./[double(acDataIn.hFactor); double(acDataIn.vFactor)];
            dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(double(acDataIn), dsmRegs, 'inverse'); % the one used for assessing LOS error
            losShift = -[double(acDataIn.hOffset)/double(dsmRegsOrig.dsmXscale);...
                double(acDataIn.vOffset)/double(dsmRegsOrig.dsmYscale)]...
                -[double(dsmRegsOrig.dsmXoffset); double(dsmRegsOrig.dsmYoffset)].*(1-losScaling);
        otherwise
            error('Only {0,1,2} are supported as values for modelFlag');
    end
    
end