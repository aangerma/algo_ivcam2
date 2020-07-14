function [resStruct] = createResultStruct(paramsIn,testOutputs,testFlowData)

% Input camera params:
inputState.hfactor = testOutputs.dbgRerun.acDataIn.hFactor;
inputState.vfactor = testOutputs.dbgRerun.acDataIn.vFactor;
inputState.Krgb = paramsIn.Krgb;
inputState.Rrgb = paramsIn.Rrgb;
inputState.Trgb = paramsIn.Trgb;
inputState.rgbRes = paramsIn.rgbRes;
inputState.rgbDistort = paramsIn.rgbDistort;

% New camera params:
outputState.Krgb = testOutputs.paramsRerun.Krgb;
outputState.Rrgb = testOutputs.paramsRerun.Rrgb;
outputState.Trgb = testOutputs.paramsRerun.Trgb;
outputState.rgbRes = testOutputs.paramsRerun.rgbRes;
outputState.rgbDistort = testOutputs.paramsRerun.rgbDistort;
outputState.hfactor = testOutputs.newAcData.hFactor;
outputState.vfactor = testOutputs.newAcData.vFactor;

outputStateNoClipping = outputState;
outputStateNoClipping.hfactor = testOutputs.dbgRerun.acDataOutPreClipping.hFactor;
outputStateNoClipping.vfactor = testOutputs.dbgRerun.acDataOutPreClipping.vFactor;


% Create test statistic line
sceneSplitted = strsplit(testFlowData.framePath,'\');
sceneName = sceneSplitted{end-3};
resStruct.Scene = sceneName;
iteration = sceneSplitted{end-2};
resStruct.Iteration = iteration;
resStruct.inputState = inputState;
resStruct.outputState = outputState;
resStruct.outputStateNoClipping = outputStateNoClipping;
resStruct.IsConverge = testOutputs.validParamsRerun;
resStruct.validInputs = testOutputs.dbgRerun.validInputs;
% resStruct.svmFeatures = testOutputs.dbgRerun.svmDebug.featuresMat;
% resStruct.svmScore = testOutputs.dbgRerun.svmDebug.distanceFromPlane;
resStruct.dbgRerun = testOutputs.dbgRerun;
resStruct = Validation.aux.mergeResultStruct(resStruct, testFlowData);

if isfield(testFlowData,'attributeNames')
    for k = 1:numel(testFlowData.attributeNames)
        resStruct.(testFlowData.attributeNames{k}) = testFlowData.attributeVals(k);
    end
end
end

 