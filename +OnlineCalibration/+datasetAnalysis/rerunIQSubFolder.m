function rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,lrsRecording)
if ~exist('lrsRecording','var')
    lrsRecording = 0;
end
if lrsRecording
    iterationDirs = dir(fullfile(rerunDir,'*_lrs_ac'));
    names = {iterationDirs.name};
    splited = split(names,'_lrs_ac');
    out=cellfun(@str2num,splited(:,:,1)');
    
else
    iterationDirs = dir(fullfile(rerunDir,'iteration*'));
    names = {iterationDirs.name};
    splited = split(names,'iteration');
    out=cellfun(@str2num,splited(:,:,2)');
end

[~,order] = sort(out);
iterationDirs = iterationDirs(order);
iterFromStart = 1;
frameList = struct('frame',{},'params',{},'dsmRegs',{},'acData',{});
for i = 1:numel(iterationDirs)
    fprintf('Iteration %d/%d\n',i,numel(iterationDirs));
    folderPath = fullfile(iterationDirs(i).folder,iterationDirs(i).name);
    if lrsRecording
        [ frame, params,dataForACTableGeneration] = getCameraParamsRaw(folderPath);
        dataForACTableGeneration.DSMRegs = dataForACTableGeneration.dsmRegs;
    else
        [frame,params,dataForACTableGeneration] = OnlineCalibration.datasetAnalysis.acIqDirToAcInputs(folderPath);
    end
    if runMultiFrame
        params = OnlineCalibration.aux.getParamsForACMF(params);
    else
        params = OnlineCalibration.aux.getParamsForAC(params);
    end
    if i == 1
        origParams = params;
        currAcData = dataForACTableGeneration;
    end
    if exist('lastParams','var')
        params = lastParams;
        params.acData = currAcData;
    end
    params.checkMovementFromLastSuccess = 0;
    params.outputFolder = fileparts(outputResFile);
    mkdirSafe(params.outputFolder);
    params.iterFromStart = iterFromStart;
    if runMultiFrame
        params.maxGlobalLosScalingStep = 0.005;
        if ~isempty(frameList)
            % Copy intrinsics & extrinsics and AC data so the chain will
            % make sense
            params = OnlineCalibration.aux.copyCameraParams(params,frameList(end).params,frameList(end).acData);
        end
        [validParamsRerun,paramsRerun,~,newAcData,dbgRerun,frameList] = OnlineCalibration.aux.runSingleMFACIteration(frame,params,origParams,dataForACTableGeneration,frameList);
    else
        if i > 1 && exist('lastValidYuy2Temp','var')
            frame.lastValidYuy2 = lastValidYuy2Temp;
        end
        [validParamsRerun,paramsRerun,~,newAcData,dbgRerun] = OnlineCalibration.aux.runSingleACIteration(frame,params,origParams,dataForACTableGeneration);
    end
    if validParamsRerun
        lastValidYuy2Temp = frame.yuy2;
    end
    results.validParamsRerun = validParamsRerun;
    results.paramsRerun = paramsRerun;
    results.newAcData = newAcData;
    results.dbgRerun = dbgRerun;
    
    res(i) = results;
    
    if validParamsRerun
        lastParams = paramsRerun;
        iterFromStart = iterFromStart+1;
        currAcData = newAcData;
        %        if runMultiFrame
        %            currAcData = dbgRerun.acDataOutPreClipping;
        %        end
    else
        lastParams = dbgRerun.params;
        currAcData = dbgRerun.acDataIn;
    end
end
save(outputResFile,'res');
end