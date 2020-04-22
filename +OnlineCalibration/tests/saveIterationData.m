function saveIterationData(outputBinFilesPath, iteration_data)

f_name = sprintf('uvmap_iteration_%d',iteration_data.iterCount);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, iteration_data.uvmap,'double');
f_name = sprintf('DVals_iteration_%d',iteration_data.iterCount);
DVals_nan = iteration_data.DVals;
DVals_nan(isnan(DVals_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, DVals_nan,'double');
f_name = sprintf('DxVals_iteration_%d',iteration_data.iterCount);
DxVals_nan = iteration_data.DxVals;
DxVals_nan(isnan(DxVals_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, DxVals_nan,'double');
f_name = sprintf('DyVals_iteration_%d',iteration_data.iterCount);
DyVals_nan = iteration_data.DyVals;
DyVals_nan(isnan(DyVals_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, DyVals_nan,'double');

calib = calibAndCostToRaw(iteration_data.calib, iteration_data.cost);
f_name = sprintf('calib_iteration_%d',iteration_data.iterCount);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, calib,'double');

gradStruct.xAlpha = iteration_data.grad.xAlpha;
gradStruct.yBeta = iteration_data.grad.yBeta;
gradStruct.zGamma = iteration_data.grad.zGamma;
gradStruct.Trgb = iteration_data.grad.T;
gradStruct.Krgb = iteration_data.grad.Krgb;
gradStruct.Rrgb = zeros(3,3);
gradStruct.rgbPmat = zeros(3,4);

grad = calibAndCostToRaw(gradStruct, 0);
f_name = sprintf('grad_iteration_%d',iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, grad,'double');

end

