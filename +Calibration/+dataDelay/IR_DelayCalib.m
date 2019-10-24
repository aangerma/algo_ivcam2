function [res, d,im,pixVar] = IR_DelayCalib(hw, delay, calibParams, Val_mode, isFinalStage, fResMirror)
    if(~exist('Val_mode','var'))
       Val_mode  = false;
    end
    if isFinalStage
        suffix = '_final';
    else
        suffix = '_init';
    end
        
    gainCalibValue  = '000ffff0';
    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30
    [delay, sz] = IR_DelayCalibInit(hw , delay ,Val_mode);
  
    %    [imU,imD]= Calibration.aux.getScanDirImgs(hw);  % seprate to get frame
    [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
    Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
    path_up = fullfile(ivcam2tempdir,sprintf('IR_Delay%s_up',suffix));
    Calibration.aux.SaveFramesWrapper(hw , 'I' , NumberOfFrames, path_up);             % get frame without post processing (averege) (SDK like)
    
    Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
    path_down = fullfile(ivcam2tempdir,sprintf('IR_delay%s_down',suffix));
    Calibration.aux.SaveFramesWrapper(hw, 'I' , NumberOfFrames, path_down);             % get frame without post processing (averege) (SDK like)
    Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values

    [res, d, im ,pixVar] = IR_DelayCalibCalc(path_up, path_down, sz, delay, calibParams, isFinalStage, fResMirror); 
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
