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
% for i = 1:20
% %     data.coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,maxCoolTime);
%     [data.framesData,data.heatingStage] = Calibration.thermal.collectTempData(hw,regs,calibParams,runParams,fprintff,maxHeatTime,app);
%     timeForCoolDown = randi(30) * 60;
%     pause(timeForCoolDown);
%     fndata = fullfile('X:\Users\tmund\X:\Users\tmund\ThermalRtdConsistenc',sprintf('data%02.0f.mat',i));
%     save(fndata,'data','timeForCoolDown');
% end

% data.coolingStage = Calibration.thermal.coolDown(hw,calibParams,runParams,fprintff,maxCoolTime);
data.coolingStage.duration = 0;
data.coolingStage.startTemp = 0;
data.coolingStage.endTemp = 0;

[data.framesData,data.heatingStage] = Calibration.thermal.collectTempData(hw,regs,calibParams,runParams,fprintff,maxHeatTime,app);


end

