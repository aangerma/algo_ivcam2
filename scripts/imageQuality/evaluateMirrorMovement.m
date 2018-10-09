function [ results ] = evaluateMirrorMovement( logfname,description )
% This function connects to the camera, collects some frames of the
%{
 checkerboard and evaluates:
1. Fill rate of scans.
2. 3D error.
3. Edges width.

It saves the reuslts in to log file (logfname). Description should be a
string that shortly describe what has been done to the mirror movement. It
is inserted to the log file.
%}
hw = HWinterface();
results.description = description;
% Measure fill rate
results.fillRate = Calibration.validation.validateScanFillRate(hw);
% Measure geometric error
% Capture three CB scenes and evaluate geometric error
darr(1)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.7 .7 1]));
darr(2)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
darr(3)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.5 .5 1]));

results.eGeom = calcGeomErr( hw,darr);
% Measure sharpness of edges
[results.horizEdge,results.vertEdge] = calcEdges(darr(1));

logResults(results,logfname);
end
function logResults(results,fname)
if exist(fname, 'file') == 2
    fname = input('Given file name already exists. Please give a new file name(*.txt):','s');
end
fid = fopen(fname,'wt');
fprintf(fid, struct2str(results));
fclose(fid);
end 
function [horizEdge,vertEdge] = calcEdges(frame)
[~, metricsResults] = Validation.metrics.gridEdgeSharp(frame, []);
horizEdge = metricsResults.horizMean;
vertEdge = metricsResults.vertMean;
% 
% fprintff('%s: UpImage=%2.2g, FinalImage=%2.2g.\n','horizSharpnessMean',,metricsResults.horizMean);
% fprintff('%s: UpImage=%2.2g, FinalImage=%2.2g.\n','vertSharpnessMean',metricsResultsU.vertMean,metricsResults.vertMean);

end
function [ eGeom ] = calcGeomErr( hw )

params.camera.K = getKMat(hw);
params.target.squareSize = 30;
for i = 1:numel(darr)
[score(i), ~] = Validation.metrics.gridInterDist(darr(i), params);
end
eGeom = mean(score);
% fprintf('%s: %2.4g\n','eGeom',score);
end


function K = getKMat(hw)
    CBUFspare = typecast(hw.read('CBUFspare'),'single');
    K = reshape([CBUFspare;1],3,3)';
    K(K<1) = 0;
end