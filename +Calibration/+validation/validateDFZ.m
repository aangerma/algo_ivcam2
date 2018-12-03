function [ dfzRes ] = validateDFZ( hw,frame,fprintff )
    dfzRes = [];
    params.camera.K = getKMat(hw);
    params.camera.zMaxSubMM = 8;
    params.target.squareSize = 30;
    [score, ~] = Validation.metrics.gridInterDist(rotFrame180(frame), params);
    dfzRes.GeometricError = score;
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