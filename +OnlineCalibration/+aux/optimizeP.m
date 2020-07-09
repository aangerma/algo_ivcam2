function [newCost,newParamsP,newParamsKzFromP,convergedReason] = optimizeP(currentFrame,params,outputBinFilesPathStruct)

% Optimize P
params.derivVar = 'P';
if ~exist('outputBinFilesPathStruct','var')
    outputBinFilesPathStruct = [];
end

[newParamsP,newCost,convergedReason] = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params,outputBinFilesPathStruct);

newParamsKzFromP = newParamsP;
newParamsKzFromP.derivVar = 'Kdepth';
[newParamsKzFromP.Krgb,newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsKzFromP.rgbPmat);
newParamsKzFromP.Krgb(1,2) = 0;
newParamsKzFromP.Kdepth([1,5]) = newParamsKzFromP.Kdepth([1,5])./newParamsKzFromP.Krgb([1,5]).*params.Krgb([1,5]);
newParamsKzFromP.Krgb([1,5]) = params.Krgb([1,5]);
newParamsKzFromP.rgbPmat = newParamsKzFromP.Krgb*[newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb];


end

