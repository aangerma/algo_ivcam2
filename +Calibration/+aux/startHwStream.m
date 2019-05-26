function [] = startHwStream(hw,runParams)
    %STARTHWSTREAM Summary of this function goes here
    %   Detailed explanation goes here
    if 1
        if isfield(runParams,'rgb') && runParams.rgb
            hw.startStream([],[],[1920 1080]);
        else
            hw.startStream;
        end
    else
        hw.startStream;
    end
   
end

