function [res, d,im,pixVar] = Z_DelayCalib(hw, path_both ,delay ,calibParams)
    gainCalibValue  = '000ffff0';
    unFiltered      = 0;
    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30

    sz = Z_DelayCalibInit(hw , delay);
    %    [imU,imD]= Calibration.aux.getScanDirImgs(hw);  % seprate to get frame
    [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
    Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
    path_up = fullfile(ivcam2tempdir,'Z_Delay_up');
    Calibration.aux.SaveFramesWrapper(hw , 'ALT_IR' , NumberOfFrames, path_up);             % get frame without post processing (averege) (SDK like)
    
    Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
    path_down = fullfile(ivcam2tempdir,'Z_Delay_down');
    Calibration.aux.SaveFramesWrapper(hw, 'ALT_IR' , NumberOfFrames, path_down);             % get frame without post processing (averege) (SDK like)
    Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values

    [res, d, im ] = Z_DelayCalibCalc(path_up, path_down, path_both , sz , delay ,calibParams); 
%%    Z_DelayCalibOuput(d, pixVar);
end


function [sz] = Z_DelayCalibInit(hw , delayZ )
    sz = hw.streamSize;
end


function  [] = Z_DelayCalibOuput(d, pixVar)
    return;
end

