function [validACConditions,dbg] = checkACConstrains(apdGain,humidityTemp,params)
% Check for correct APD state (it has a control, should be in the value of
% one of the presets)
dbg.validPreset = apdGain == 9 || apdGain == 18;
% As long as we don't support the thermal fix, we should only apply it when
% the temperature is close to calibration temp
dbg.validTemperature = humidityTemp >= params.minHumTh && humidityTemp <= params.maxHumTh;

validACConditions = dbg.validPreset && dbg.validTemperature;
end

