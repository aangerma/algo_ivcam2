function rerunAc2_1DataCollectionSubFolder(rerunDir,outputResFile,runMultiFrame)
iterationDirs = dir(fullfile(rerunDir,'*_algo_ac'));
names = {iterationDirs.name};
splited = split(names,'_algo_ac');
if numel(size(splited))< 3
    out=cellfun(@str2num,splited(1));
else
    out=cellfun(@str2num,splited(:,:,1)');
end
[~,order] = sort(out);
iterationDirs = iterationDirs(order);
iterFromStart = 1;
frameList = struct('frame',{},'params',{},'dsmRegs',{},'acData',{});
for i = 1:numel(iterationDirs)
    fprintf('Iteration %d/%d\n',i,numel(iterationDirs));
    folderPath = fullfile(iterationDirs(i).folder,iterationDirs(i).name);
    if isempty(dir(fullfile(folderPath,'**','InputData.mat')))
        continue;
    end
    try
        scene_data_folder = dir(fullfile(folderPath,'**','InputData.mat'));
        load(fullfile(scene_data_folder.folder,'InputData.mat'),'frame','params','ac2_dsm_params');
    catch e
        if contains(e.message,'File might be corrupt')
            continue;
        else
            error('Something is wrong!');
        end
    end
    [frame,params,dataForACTableGeneration] = OnlineCalibration.datasetAnalysis.ac2_1DataCollectionDirToAcInputs(folderPath);
    if runMultiFrame
        params = OnlineCalibration.aux.getParamsForACMF(params);
    else
        if ~isfield(params,'manualTrigger')
            params.manualTrigger = 0;
        end
        params = OnlineCalibration.aux.getParamsForAC(params,params.manualTrigger);
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
            if any(size(frame.yuy2) ~= size(lastValidYuy2Temp))
                continue;
            end
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