function [ dfzRes,allRes,dbg ] = validateDFZ( hw,frames,fprintff,calibParams)
    dfzRes = [];
    params.camera.K = getKMat(hw);
    params.camera.zMaxSubMM = 2^double(hw.read('GNRLzMaxSubMMExp'));
    params.target.squareSize = calibParams.validationConfig.cbSquareSz;
    params.expectedGridSize = calibParams.validationConfig.cbGridSz;
    [score, allRes] = Validation.metrics.gridInterDist(rotFrame180(frames), params);
    dfzRes.GeometricError = score;
    [~, geomRes,dbg] = Validation.metrics.geomUnproject(rotFrame180(frames), params);
    dfzRes.reprojRmsPix = geomRes.reprojRmsPix;
    dfzRes.reprojZRms = geomRes.reprojZRms;
    dfzRes.irDistanceDrift = geomRes.irDistanceDrift;
    allRes = Validation.aux.mergeResultStruct(allRes,geomRes);
    
    fprintff('%s: %2.4g\n','eGeom',score);
end

function rotFrame = rotFrame180(frame)
    rotFrame.i = rot90(frame.i,2);
    rotFrame.z = rot90(frame.z,2);
    rotFrame.c = rot90(frame.c,2);
end
function K = getKMat(hw)
    CBUFspare = typecast(hw.read('CBUFspare'),'single');
    K = reshape([CBUFspare;1],3,3)';
end