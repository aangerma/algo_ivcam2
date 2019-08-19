function [ dfzRes,allRes,dbg ] = validateDFZ( hw,frames,fprintff,calibParams,runParams)
    params.camera.K = getKMat(hw);
    params.camera.zMaxSubMM = 2^double(hw.read('GNRLzMaxSubMMExp'));
    params.target.squareSize = calibParams.validationConfig.target.cbSquareSz;
    params.target.name = calibParams.validationConfig.target.name;
    params.expectedGridSize = calibParams.validationConfig.cbGridSz;
    params.sampleZFromWhiteCheckers = calibParams.validationConfig.sampleZFromWhiteCheckers;
    params.validateOnCenter = calibParams.validationConfig.validateOnCenter;
    params.roi = calibParams.validationConfig.roi4ValidateOnCenter;
    params.plainFitMaskIsRoiRect = calibParams.validationConfig.plainFitMaskIsRoiRect;
    params.gidMaskIsRoiRect = calibParams.validationConfig.gidMaskIsRoiRect;
    [dfzRes,allRes,dbg] = Calibration.validation.DFZCalc(params,frames,runParams,fprintff);
end
function K = getKMat(hw)
    CBUFspare = typecast(hw.read('CBUFspare'),'single');
    K = reshape([CBUFspare;1],3,3)';
end