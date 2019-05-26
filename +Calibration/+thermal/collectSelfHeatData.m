function [ data] = collectSelfHeatData(hw,data,calibParams,runParams,fprintff,maximalCoolingAngHeatingTimes,app)
% Do a cycle of cooling and heating. Collect data during the heatin stage
regs = data.regs;
if isempty(maximalCoolingAngHeatingTimes)
    maxCoolTime = inf;
    maxHeatTime = inf;
else
    maxCoolTime = maximalCoolingAngHeatingTimes(1);
    maxHeatTime = maximalCoolingAngHeatingTimes(2);    
end
% for i = 1:2
data.coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,maxCoolTime);
[data.framesData,data.heatingStage] = Calibration.thermal.collectTempData(hw,regs,calibParams,runParams,fprintff,maxHeatTime,app);
%     fndata = fullfile('X:\Users\tmund\pzrThermalDebug308',sprintf('data%02.0f.mat',i));
%     save(fndata,'data');
% end
end

