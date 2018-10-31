function [  ] = validateDFZ( hw,frame,fprintff )
params.camera.K = getKMat(hw);
params.target.squareSize = 30;
[score, ~] = Validation.metrics.gridInterDist(rotFrame180(frame), params);
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