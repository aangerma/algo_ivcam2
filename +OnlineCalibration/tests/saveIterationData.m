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

f_name = sprintf('xy_iteration_%d',iteration_data.iterCount);
x1_nan = iteration_data.x1;
x1_nan(isnan(x1_nan)) = realmax;
y1_nan = iteration_data.y1;
y1_nan(isnan(y1_nan)) = realmax;

OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, [x1_nan; y1_nan]','double');

f_name = sprintf('rc_iteration_%d',iteration_data.iterCount);
Rc_nan = iteration_data.rc;
Rc_nan(isnan(Rc_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, Rc_nan','double');

f_name = sprintf('xCoeff_Krgb_%d',iteration_data.iterCount);
xCoeffValKrgb_nan = [iteration_data.xCoeffValKrgb(:,1) iteration_data.xCoeffValKrgb(:,5) iteration_data.xCoeffValKrgb(:,3)  iteration_data.xCoeffValKrgb(:,6)];
xCoeffValKrgb_nan(isnan(xCoeffValKrgb_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, xCoeffValKrgb_nan,'double');

f_name = sprintf('yCoeff_Krgb_%d',iteration_data.iterCount);
yCoeffValKrgb_nan = [iteration_data.yCoeffValKrgb(:,1) iteration_data.yCoeffValKrgb(:,5) iteration_data.yCoeffValKrgb(:,3)  iteration_data.yCoeffValKrgb(:,6)];
yCoeffValKrgb_nan(isnan(yCoeffValKrgb_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, yCoeffValKrgb_nan,'double');

f_name = sprintf('xCoeff_R_%d',iteration_data.iterCount);
xCoeffValR_nan = [iteration_data.xCoeffValR.xAlpha' iteration_data.xCoeffValR.yBeta' iteration_data.xCoeffValR.zGamma'];
xCoeffValR_nan(isnan(xCoeffValR_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, xCoeffValR_nan,'double');

f_name = sprintf('xCoeff_P_%d',iteration_data.iterCount);
xCoeffValP_nan = [iteration_data.xCoeffValP];
xCoeffValP_nan(isnan(xCoeffValP_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, xCoeffValP_nan,'double');


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

