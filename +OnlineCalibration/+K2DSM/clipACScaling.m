function [acDataNew,performedClipping] = clipACScaling(acData,acDataIn,maxGlobalLosScalingStep)
performedClipping = 0;
acDataNew = acData;
if abs(acDataNew.hFactor - acDataIn.hFactor) > maxGlobalLosScalingStep
    acDataNew.hFactor = acDataIn.hFactor + (acDataNew.hFactor - acDataIn.hFactor)/abs(acDataNew.hFactor - acDataIn.hFactor)*maxGlobalLosScalingStep;    
    performedClipping = 1;
end
if abs(acDataNew.vFactor - acDataIn.vFactor) > maxGlobalLosScalingStep
    acDataNew.vFactor = acDataIn.vFactor + (acDataNew.vFactor - acDataIn.vFactor)/abs(acDataNew.vFactor - acDataIn.vFactor)*maxGlobalLosScalingStep;    
    performedClipping = 1;
end

end

