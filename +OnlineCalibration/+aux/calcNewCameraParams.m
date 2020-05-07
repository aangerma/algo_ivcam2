function [params,frame,outputToIgnore,validParams,dbg] = calcNewCameraParams(hw,params,originalParams,inputToIgnore1,inputToIgnore2,flowParams,acTableHeadPath)
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
    
    dataForACTableGeneration = OnlineCalibration.K2DSM.readDataForK2DSM(hw);
    
    [validParams,params,newAcDataTable,~,dbg] = OnlineCalibration.aux.runSingleACIteration(frame,params,originalParams,dataForACTableGeneration);
    if validParams
        params.iterFromStart = params.iterFromStart + 1;
        % Create and burn new AC table
        tablefn = OnlineCalibration.aux.saveNewACTable(newAcDataTable,acTableHeadPath);
        hw.cmd(sprintf('WrCalibInfo %s',tablefn));
        return;
    else
        fprintf('Invalid optimization... \n');
        pause(flowParams.pauseTimeAfterInvalidScene);
        continue;
    end
end

end

