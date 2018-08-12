function [  ] = validateDFZ( hw,fprintff )
frame = hw.getFrame(30);
params.camera.K = getKMat(hw);
params.target.squareSize = 30;
[score, results] = Validation.metrics.gridInterDist(frame, params);
fprintff('%s: %2.2g\n','eGeom',score);
end


function K = getKMat(hw)
    CBUFspare = typecast(hw.read('CBUFspare'),'single');
    K = reshape([CBUFspare;1],3,3)';
end