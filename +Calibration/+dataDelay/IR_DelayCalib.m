function [res, d,im,pixVar] = IR_DelayCalib(hw, delay, calibParams, Val_mode, isFinalStage, fResMirror)
    if(~exist('Val_mode','var'))
       Val_mode  = false;
    end
        
    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30
    [delay, sz] = IR_DelayCalibInit(hw , delay ,Val_mode);
  
    [ addresses2save, values2save ] = Calibration.aux.getScanDirectionValues( hw );% save original scan values
    hw.runPresetScript('projectOnlyUpward');  % Scan Direction up
    frameBytesUp = Calibration.aux.captureFramesWrapper(hw, 'I', NumberOfFrames);
    Calibration.aux.setScanDirectionValues( hw,addresses2save, values2save ); % resore gain inital values
    
    hw.runPresetScript('projectOnlyDownward'); % Scan Direction down
    frameBytesDown = Calibration.aux.captureFramesWrapper(hw, 'I', NumberOfFrames);
    Calibration.aux.setScanDirectionValues( hw,addresses2save, values2save ); % resore gain inital values

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
