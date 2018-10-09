function [  ] = validateDFZ( hw,frame,fprintff )
params.camera.K = getKMat(hw);
params.target.squareSize = 30;
[score, results] = Validation.metrics.gridInterDist(frame, params);
fprintff('%s: %2.4g\n','eGeom',score);
end


function K = getKMat(hw)
    CBUFspare = typecast(hw.read('CBUFspare'),'single');
    K = reshape([CBUFspare;1],3,3)';
end