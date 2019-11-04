function [res, d,im,pixVar] = Z_DelayCalib(hw, depthDataBoth, delay, calibParams, isFinalStage, fResMirror)

    gainCalibValue  = '000ffff0';
    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30

    sz = Z_DelayCalibInit(hw , delay);
    %    [imU,imD]= Calibration.aux.getScanDirImgs(hw);  % seprate to get frame
    [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
    Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
    depthDataUp = captureFramesWrapper(hw, 'ALT_IR', NumberOfFrames);
    
    Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
    depthDataDown = captureFramesWrapper(hw, 'ALT_IR', NumberOfFrames);
    Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values

    [res, d, im ] = Z_DelayCalibCalc(depthDataUp, depthDataDown, depthDataBoth, sz, delay, calibParams, isFinalStage, fResMirror); 
%%    Z_DelayCalibOuput(d, pixVar);
end


function [sz] = Z_DelayCalibInit(hw , delayZ )
    sz = hw.streamSize;
end


function  [] = Z_DelayCalibOuput(d, pixVar)
    return;
end

