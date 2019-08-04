function [  ] = switchPresetAndUpdateModRef( hw,presetNum,calibParams,results )
if presetNum == 2 % Short range
    hw.setPresetControlState(2);
    if exist('results','var')
        if isfield(results,'maxModRefDec') && isfield(results,'minRangeScaleModRef')
            Calibration.aux.RegistersReader.setModRef(hw,round(results.maxModRefDec*results.minRangeScaleModRef)); 
            pause(3); 
        end
    end
elseif presetNum == 1 % Long range
    hw.setPresetControlState(1);
    if isfield(calibParams,'presets')
        if calibParams.presets.long.updateCalibVal
            if exist('results','var')
                if isfield(results,'maxModRefDec') && isfield(results,'maxRangeScaleModRef')
                    Calibration.aux.RegistersReader.setModRef(hw,round(results.maxModRefDec*results.maxRangeScaleModRef)); 
                    pause(3); 
                end
            end
        end
    else 
        warning('No preset field in calib param, Mod ref is not updated'); 
    end 
else
    error('Unknown preset num %d \n',presetNum);
end
end

