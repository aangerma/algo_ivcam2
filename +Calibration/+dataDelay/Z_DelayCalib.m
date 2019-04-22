function [res, d,im,pixVar] = Z_DelayCalib(hw, path_both ,delay ,calibParams)
    gainCalibValue  = '000ffff0';
    unFiltered      = 0;
    NumberOfFrames  = calibParams.gnrl.Nof2avg; % should be 30
    width           = calibParams.gnrl.internalImSize(2); % take it from configurtation
    hight           = calibParams.gnrl.internalImSize(1);
    
    Z_DelayCalibInit(hw , delay);
    %    [imU,imD]= Calibration.aux.getScanDirImgs(hw);  % seprate to get frame
    [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
    Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
    path_up = fullfile(tempdir,'Z_Delay_up');
    Calibration.aux.SaveFramesWrapper(hw , 'ALT_IR' , NumberOfFrames, path_up);             % get frame without post processing (averege) (SDK like)
    
    Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
    path_down = fullfile(tempdir,'Z_Delay_down');
    Calibration.aux.SaveFramesWrapper(hw, 'ALT_IR' , NumberOfFrames, path_down);             % get frame without post processing (averege) (SDK like)
    Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values

    [res, d, im ] = Z_DelayCalibCalc(path_up, path_down, path_both , width , hight , delay ,calibParams); 
%{
    imUs_i = GetFramesFromDir(path_up   ,width , hight);
    imDs_i = GetFramesFromDir(path_down ,width , hight);
    imDs_b = GetFramesFromDir(path_both ,width , hight);

    [res, d, im ,pixVar] = Calibration.CompiledAPI.Z_DelayCalibCalc(imUs_i,imDs_i, im_b , delay ,calibParams); 
%}
%%    Z_DelayCalibOuput(d, pixVar);
end


function [] = Z_DelayCalibInit(hw , delayZ )
    return;
end


function  [] = Z_DelayCalibOuput(d, pixVar)
    return;
end

