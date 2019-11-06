function [] = startHwStream(hw,runParams)
%STARTHWSTREAM Summary of this function goes here
%   Detailed explanation goes here
if 1
    if isfield(runParams,'rgb') && runParams.rgb
        if ~isfield(runParams, 'rgbRes')
            runParams.rgbRes = [1920 1080];
        end
        hw.startStream([],runParams.calibRes,runParams.rgbRes);
    else
        hw.startStream(0,runParams.calibRes);
    end
else
    hw.startStream(0,runParams.calibRes);
end

end
