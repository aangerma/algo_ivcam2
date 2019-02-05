function [ v,gridPoints ] = regular2xyz( frames,params )
%REGULAR2XYZ Summary of this function goes here
%   Detailed explanation goes here


[gridPoints, ~] = Validation.aux.findCheckerboard(frames.i, params.expectedGridSize);
gridPoints = gridPoints-1;
v = Validation.aux.pointsToVertices(gridPoints, frames.z, params.camera);
end

