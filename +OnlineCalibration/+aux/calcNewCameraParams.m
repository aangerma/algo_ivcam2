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
    
    params.apdGain = hw.getApdGainState();
    [params.humidityTemp,~] = hw.getHumidityTemperature();
    params = OnlineCalibration.aux.getParamsForAC(params,flowParams.manualTrigger);

    [validACConditions,dbg] = OnlineCalibration.aux.checkACConstrains(params.apdGain,params.humidityTemp,params);
    if ~validACConditions
       return; 
    end
    dataForACTableGeneration = OnlineCalibration.K2DSM.readDataForK2DSM(hw);
    [validParams,params,newAcDataTable,~,dbg] = OnlineCalibration.aux.runSingleACIteration(frame,params,originalParams,dataForACTableGeneration);
    dbg.dataForACTableGeneration = dataForACTableGeneration;
    if validParams 
        params.iterFromStart = params.iterFromStart + 1;
        if ~isfield(params, 'burnToUnit')
            params.burnToUnit = true;
        end
        if params.burnToUnit
            % Create and burn new AC table
            hw.stopStream()
            tablefn = OnlineCalibration.aux.saveNewACTable(newAcDataTable,acTableHeadPath);
            hw.cmd(sprintf('WrCalibInfo %s',tablefn));
        end
        return;
    else
        fprintf('Invalid optimization... \n');
        pause(flowParams.pauseTimeAfterInvalidScene);
        continue;
    end
end

end

