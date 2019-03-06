function [ framesData ,data] = collectSelfHeatData(hw,regs,calibParams,runParams,fprintff)
% Do a cycle of cooling and heating. Collect data during the heatin stage

data.coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff);
[framesData,data.heatingStage] = Calibration.thermal.collectTempData(hw,regs,calibParams,runParams,fprintff);

end

