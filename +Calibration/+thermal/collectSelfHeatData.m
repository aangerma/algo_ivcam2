function [ data] = collectSelfHeatData(hw,data,calibParams,runParams,fprintff,maximalCoolingAngHeatingTimes)
% Do a cycle of cooling and heating. Collect data during the heatin stage
regs = data.regs;
if isempty(maximalCoolingAngHeatingTimes)
    maxCoolTime = inf;
    maxHeatTime = inf;
else
    maxCoolTime = maximalCoolingAngHeatingTimes(1);
    maxHeatTime = maximalCoolingAngHeatingTimes(2);    
end
data.coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,maxCoolTime);
[data.framesData,data.heatingStage] = Calibration.thermal.collectTempData(hw,regs,calibParams,runParams,fprintff,maxHeatTime);

end

