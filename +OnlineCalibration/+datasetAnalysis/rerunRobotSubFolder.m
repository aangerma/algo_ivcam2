function rerunRobotSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes,initAcData)
files = dir(fullfile(rerunDir,'*_data.mat'));
names = {files.name};
splited = split(names,'_');
out=cellfun(@str2num,splited(:,:,1)');
[~,order] = sort(out);
files = files(order);
iterFromStart = 1;
frameList = struct('frame',{},'params',{},'dsmRegs',{},'acData',{});
for i = 1:numel(files)
    load(fullfile(files(i).folder,files(i).name));
    if i == 1
       origParams = originalParams;
       currAcData = initAcData;
    end
    if exist('lastParams','var')
       params = lastParams; 
    end
    params.checkMovementFromLastSuccess = 0;
    % params.outputFolder = 'X:\Users\dbg1212';
    dataForACTableGeneration = dbg.dataForACTableGeneration;
    params = OnlineCalibration.aux.getParamsForAC(params);
    params.acData = currAcData;
    params.iterFromStart = iterFromStart;
    if runMultiFrame
        params.numberOfScenes = numberOfScenes;    
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
    % fprintf('[%d]',validParamsRerun(i));
    % v(i) = validParams;
    results.validParamsRerun = validParamsRerun;
    results.paramsRerun = paramsRerun;
    results.newAcData = newAcData;
    results.dbgRerun = dbgRerun;
    
    res(i) = results;

    if validParamsRerun
       lastParams = paramsRerun;
       iterFromStart = iterFromStart+1; 
       currAcData = newAcData;
       if runMultiFrame
           currAcData = dbgRerun.acDataOutPreClipping;
       end
    end
end
save(outputResFile,'res');
end