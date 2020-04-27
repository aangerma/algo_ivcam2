function [params,frame,outputToIgnore,validParams,dbg] = calcNewCameraParams(hw,params,originalParams,inputToIgnore1,inputToIgnore2,flowParams)
outputToIgnore = [];
validParams = -1;
dbg = []; 
loopCounter = 0;
while loopCounter <= params.maxIters 
    loopCounter = loopCounter + 1;
    frame = hw.getFrame(1,1,1);
    frame.i = double(frame.i);
    frame.z = double(frame.z);
    frame.yuy2Prev = hw.getColorFrame(1).color;
    frame.yuy2 = hw.getColorFrame(1).color;
    
    [validParams,params,dbg] = OnlineCalibration.aux.runSingleACIteration(frame,params,originalParams);
    if validParams
        params.iterFromStart = params.iterFromStart + 1;
        return;
    else
        fprintf('Invalid optimization... \n');
        pause(flowParams.pauseTimeAfterInvalidScene);
        continue;
    end
end

end

