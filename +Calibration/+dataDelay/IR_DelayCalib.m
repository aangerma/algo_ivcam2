function [res, d,im,pixVar] = IR_DelayCalib(hw, delay, calibParams, Val_mode, isFinalStage, fResMirror)
    if(~exist('Val_mode','var'))
       Val_mode  = false;
    end
        
    gainCalibValue  = '000ffff0';
    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30
    [delay, sz] = IR_DelayCalibInit(hw , delay ,Val_mode);
  
    [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
    Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
    frameBytesUp = Calibration.aux.captureFramesWrapper(hw, 'I', NumberOfFrames);
    
    Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
    frameBytesDown = Calibration.aux.captureFramesWrapper(hw, 'I', NumberOfFrames);
    Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values

    [res, d, im ,pixVar] = IR_DelayCalibCalc(frameBytesUp, frameBytesDown, sz, delay, calibParams, isFinalStage, fResMirror); 
%%    IR_DelayCalibOuput(d, pixVar);
end


function [delayIR,sz] = IR_DelayCalibInit(hw , delayIR ,valMode)
sz = hw.streamSize;
if valMode
    delayIR = 0;
else
    Calibration.dataDelay.setAbsDelay(hw,[],delayIR);  % todo change to set only slow delay
end


end


function  [] = IR_DelayCalibOuput(d, pixVar)
    return;
end
