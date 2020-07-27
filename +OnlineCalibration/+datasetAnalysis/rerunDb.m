function [resStruct,errStruct] = rerunDb(dbData,dbAnalysisFlags)

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
for n = 1:augPerScene
for iTest = 1:nFrames
    try
        if dbAnalysisFlags.rerunWaitBar && wb.isvalid
            waitbar((iTest+(n-1)*nFrames)/(nFrames*augPerScene),wb,sprintf('Rerunning Database... Please wait... \n %d/%d',(iTest+(n-1)*nFrames),(nFrames*augPerScene)));
        end
        if any(strcmp(dbData.unitSnAll{iTest},dbAnalysisFlags.ignoredSerials)) % Temporal until LUT is corrected
            continue;
        end
        params = dbData.paramsAll(iTest);
        [frame,params.apdGain] = OnlineCalibration.datasetAnalysis.loadFrame(dbData.framePathsAll{iTest},dbData.dbTypeAll(iTest,:));
        [params] = OnlineCalibration.aux.getParamsForAC(params);
        if dbAnalysisFlags.rerunWithDSMAug
            params.acData = OnlineCalibration.aux.defaultACTable();
            params.acData.hFactor = ((rand*4-2)+100)/100;
            params.acData.vFactor = ((rand*4-2)+100)/100;
        end
        [validParamsRerun,paramsRerun,~,newAcData,dbgRerun] = OnlineCalibration.aux.runSingleACIteration(frame,params,params,dbData.acInputDataAll(iTest));
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
    end
end
end
if dbAnalysisFlags.rerunWaitBar && wb.isvalid
    close(wb);
end

end

