function [newCost,newParamsP,newParamsKzFromP,iterCount] = optimizeP(currentFrame,params,outputBinFilesPath,cycle)

% Optimize P
params.derivVar = 'P';
[newParamsP,newCost,iterCount] = OnlineCalibration.Opt.optimizeParametersP(currentFrame,params,outputBinFilesPath,cycle);

newParamsKzFromP = newParamsP;
newParamsKzFromP.derivVar = 'Kdepth';
[newParamsKzFromP.Krgb,newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb] = OnlineCalibration.aux.decomposePMat(newParamsKzFromP.rgbPmat);
newParamsKzFromP.Krgb(1,2) = 0;
newParamsKzFromP.Kdepth([1,5]) = newParamsKzFromP.Kdepth([1,5])./newParamsKzFromP.Krgb([1,5]).*params.Krgb([1,5]);
newParamsKzFromP.Krgb([1,5]) = params.Krgb([1,5]);
newParamsKzFromP.rgbPmat = newParamsKzFromP.Krgb*[newParamsKzFromP.Rrgb,newParamsKzFromP.Trgb];


end

