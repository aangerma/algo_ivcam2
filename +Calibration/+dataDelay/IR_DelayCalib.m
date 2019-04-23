function [res, d,im,pixVar] = IR_DelayCalib(hw, delay ,calibParams , Val_mode)
%function [res, d,im,pixVar] = IR_DelayCalib(hw, delay ,calibParams)
    if(~exist('Val_mode','var'))
       Val_mode  = false;
    end
        
    gainCalibValue  = '000ffff0';
    unFiltered      = 0;
    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30
    width           = calibParams.gnrl.internalImSize(2); % take it from configurtation
    hight           = calibParams.gnrl.internalImSize(1);
    if (Val_mode == false)
        IR_DelayCalibInit(hw , delay);
    else 
        delay = 0; 
    end
    %    [imU,imD]= Calibration.aux.getScanDirImgs(hw);  % seprate to get frame
    [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
    Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
    path_up = fullfile(tempdir,'IR_Delay_up');
    Calibration.aux.SaveFramesWrapper(hw , 'I' , NumberOfFrames, path_up);             % get frame without post processing (averege) (SDK like)
    
    Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
    path_down = fullfile(tempdir,'IR_delay_down');
    Calibration.aux.SaveFramesWrapper(hw, 'I' , NumberOfFrames, path_down);             % get frame without post processing (averege) (SDK like)
    Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values

    [res, d, im ,pixVar] = IR_DelayCalibCalc(path_up, path_down, width , hight , delay ,calibParams); 
%%    IR_DelayCalibOuput(d, pixVar);
end


function [] = IR_DelayCalibInit(hw , delayIR )
    Calibration.dataDelay.setAbsDelay(hw,[],delayIR);  % todo change to set only slow delay
    return;
end


function  [] = IR_DelayCalibOuput(d, pixVar)
    return;
end
