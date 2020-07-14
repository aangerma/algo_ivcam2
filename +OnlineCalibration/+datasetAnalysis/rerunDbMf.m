function [resStruct,errStruct] = rerunDbMf(dbData,dbAnalysisFlags)

resStruct = struct();
ridx = 1;
errStruct = struct();
errIx = 1;
nFrames = numel(dbData.framePathsAll);
if dbAnalysisFlags.rerunWaitBar
    wb = waitbar(0,'Rerunning Database... Please wait...');
end
if dbAnalysisFlags.rerunWithDSMAug
    augPerScene = dbAnalysisFlags.rerunAugPerScene; 
else
    augPerScene = 1;
end

% Sort by serial (Multi Frame can work only on captures with the same
% serial)

for n = 1:augPerScene
for iTest = 1:nFrames
    try
        if dbAnalysisFlags.rerunWaitBar && wb.isvalid
            waitbar((iTest+(n-1)*nFrames)/(nFrames*augPerScene),wb,sprintf('Rerunning Database... Please wait... \n %d/%d',(iTest+(n-1)*nFrames),(nFrames*augPerScene)));
        end
        if any(strcmp(dbData.unitSnAll{iTest},dbAnalysisFlags.ignoredSerials)) % Temporal until LUT is corrected
            continue;
        end
        % If we finished with the current serial, end the chain
        if iTest == 1 || ~strcmp(dbData.unitSnAll{iTest},dbData.unitSnAll{iTest-1})
            frameList = struct('frame',{},'params',{},'dsmRegs',{},'acData',{});
        end
        
        params = dbData.paramsAll(iTest);
        [params] = OnlineCalibration.aux.getParamsForACMF(params);
        [frame] = OnlineCalibration.datasetAnalysis.loadFrame(dbData.framePathsAll{iTest},dbData.dbTypeAll(iTest,:));
        if isempty(frameList)
            % Augmentation can only be applied to the first scene in the
            % chain
            if dbAnalysisFlags.rerunWithDSMAug
                params.acData = OnlineCalibration.aux.defaultACTable();
                params.acData.hFactor = ((rand*4-2)+100)/100;
                params.acData.vFactor = ((rand*4-2)+100)/100;
            end
        else
            % Copy intrinsics & extrinsics and AC data so the chain will
            % make sense
            params = OnlineCalibration.aux.copyCameraParams(params,frameList(end).params,frameList(end).acData);
        end
        [validParamsRerun,paramsRerun,~,newAcData,dbgRerun,frameList] = OnlineCalibration.aux.runSingleMFACIteration(frame,params,params,dbData.acInputDataAll(iTest),frameList);               

        if isfield(dbAnalysisFlags,'saveExamplesPath') && ~isempty(dbAnalysisFlags.saveExamplesPath)
            OnlineCalibration.aux.saveExampleFrames(dbAnalysisFlags.saveExamplesPath,frame,dbgRerun.svmDebug.distanceFromPlane,dbgRerun.xyIm,dbgRerun.uvMapOrig,dbgRerun.uvMapNew);
        end
        % Calculate the result structure:
        testOutputs = struct('validParamsRerun',validParamsRerun,'paramsRerun',paramsRerun,'newAcData',newAcData,'dbgRerun',dbgRerun);
        testFlowData = struct('unitID',dbData.unitSnAll{iTest},'framePath',dbData.framePathsAll{iTest},'lutPath',dbData.lutPathsAll{iTest});
        if ~isempty(dbData.queryParamsValsAll)
            testFlowData.attributeNames = attributeNames;
            testFlowData.attributeVals = dbData.queryParamsValsAll(iTest);
        end
        resStructTemp = OnlineCalibration.datasetAnalysis.createResultStruct(params,testOutputs,testFlowData);
        if ridx == 1
            resStruct = resStructTemp;
        end
        resStruct(ridx) = resStructTemp;
        ridx = ridx + 1;
    catch ex
        disp(['Error Occurred! ' ex.message])
        errStruct(errIx).exception = ex;
        if exist('framePathsAll','var') && exist('iTest','var')
            errStruct(errIx).framePath = dbData.framePathsAll{iTest};
        end
        errIx = errIx + 1;
        disp(dbData.framePathsAll{iTest});
    end
end
end
if dbAnalysisFlags.rerunWaitBar && wb.isvalid
    close(wb);
end

end

