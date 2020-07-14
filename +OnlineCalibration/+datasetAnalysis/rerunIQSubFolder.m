function rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes)
iterationDirs = dir(fullfile(rerunDir,'iteration*'));
names = {iterationDirs.name};
splited = split(names,'iteration');
out=cellfun(@str2num,splited(:,:,2)');
[~,order] = sort(out);
iterationDirs = iterationDirs(order);
iterFromStart = 1;
frameList = struct('frame',{},'params',{},'dsmRegs',{},'acData',{});
for i = 1:numel(iterationDirs)
    fprintf('Iteration %d/%d\n',i,numel(iterationDirs));
    folderPath = fullfile(iterationDirs(i).folder,iterationDirs(i).name);
    [frame,params,dataForACTableGeneration] = OnlineCalibration.datasetAnalysis.acIqDirToAcInputs(folderPath);
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
    params.outputFolder = 'X:\Users\tmund\dbg';
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
        [validParamsRerun,paramsRerun,~,newAcData,dbgRerun] = OnlineCalibration.aux.runSingleACIteration(frame,params,origParams,dataForACTableGeneration);    
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