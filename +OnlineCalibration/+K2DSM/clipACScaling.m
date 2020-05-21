function [acDataNew] = clipACScaling(acData,acDataIn,maxGlobalLosScalingStep)

acDataNew = acData;
if abs(acDataNew.hFactor - acDataIn.hFactor) > maxGlobalLosScalingStep
    acDataNew.hFactor = acDataIn.hFactor + (acDataNew.hFactor - acDataIn.hFactor)/abs(acDataNew.hFactor - acDataIn.hFactor)*maxGlobalLosScalingStep;    
end
if abs(acDataNew.vFactor - acDataIn.vFactor) > maxGlobalLosScalingStep
    acDataNew.vFactor = acDataIn.vFactor + (acDataNew.vFactor - acDataIn.vFactor)/abs(acDataNew.vFactor - acDataIn.vFactor)*maxGlobalLosScalingStep;    
end

end

