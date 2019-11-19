function [res, d,im,pixVar] = Z_DelayCalib(hw, frameBytesBoth, delay, runParams, calibParams, isFinalStage, fResMirror)


    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30

    sz = Z_DelayCalibInit(hw , delay);
    
    [ addresses2save, values2save ] = Calibration.aux.getScanDirectionValues( hw );% save original scan values
    hw.runPresetScript('projectOnlyUpward');  % Scan Direction up
    frameBytesUp = Calibration.aux.captureFramesWrapper(hw, 'ALT_IR', NumberOfFrames);
    Calibration.aux.setScanDirectionValues( hw,addresses2save, values2save ); % resore gain inital values
    
    hw.runPresetScript('projectOnlyDownward'); % Scan Direction down
    frameBytesDown = Calibration.aux.captureFramesWrapper(hw, 'ALT_IR', NumberOfFrames);
    Calibration.aux.setScanDirectionValues( hw,addresses2save, values2save ); % resore gain inital values
    [res, d, im ] = Z_DelayCalibCalc(frameBytesUp, frameBytesDown, frameBytesBoth, sz, delay, calibParams, isFinalStage, fResMirror); 
%%    Z_DelayCalibOuput(d, pixVar);
end


function [sz] = Z_DelayCalibInit(hw , delayZ )
    sz = hw.streamSize;
end


function  [] = Z_DelayCalibOuput(d, pixVar)
    return;
end

