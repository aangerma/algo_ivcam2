function saveIterationData(outputBinFilesPath, iteration_data)

f_name = sprintf('uvmap_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, iteration_data.uvmap,'double');

f_name = sprintf('DVals_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
DVals_nan = iteration_data.DVals;
DVals_nan(isnan(DVals_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, DVals_nan,'double');

f_name = sprintf('DxVals_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
DxVals_nan = iteration_data.DxVals;
DxVals_nan(isnan(DxVals_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, DxVals_nan,'double');

f_name = sprintf('DyVals_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
DyVals_nan = iteration_data.DyVals;
DyVals_nan(isnan(DyVals_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, DyVals_nan,'double');

f_name = sprintf('xy_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
x1_nan = iteration_data.x1;
x1_nan(isnan(x1_nan)) = realmax;
y1_nan = iteration_data.y1;
y1_nan(isnan(y1_nan)) = realmax;

OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, [x1_nan; y1_nan]','double');

f_name = sprintf('rc_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
Rc_nan = iteration_data.rc;
Rc_nan(isnan(Rc_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, Rc_nan','double');

f_name = sprintf('xCoeff_P_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
xCoeffValP_nan = [iteration_data.xCoeffValP];
xCoeffValP_nan(isnan(xCoeffValP_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, xCoeffValP_nan,'double');

f_name = sprintf('yCoeff_P_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);
yCoeffValP_nan = [iteration_data.yCoeffValP];
yCoeffValP_nan(isnan(yCoeffValP_nan)) = realmax;
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, yCoeffValP_nan,'double');

grad = iteration_data.grad.P';
f_name = sprintf('grad_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, grad(:)','double');

norma = iteration_data.norma;
f_name = sprintf('grad_norma_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, norma,'double');

BacktrackingLineIterCount = iteration_data.BacktrackingLineIterCount;
f_name = sprintf('back_tracking_line_iter_count_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, BacktrackingLineIterCount,'double');

t = iteration_data.t;
f_name = sprintf('t_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, t,'double');

grads_norm = iteration_data.grads_norm';
f_name = sprintf('grads_norm_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, grads_norm(:)','double');

normalized_grads = iteration_data.normalized_grads';
f_name = sprintf('normalized_grads_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, normalized_grads(:)','double');

p_matrix = iteration_data.p_matrix';
f_name = sprintf('p_matrix_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, p_matrix(:)','double');

Krgb = iteration_data.Krgb';
f_name = sprintf('Krgb_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, Krgb(:)','double');

unit_grad = iteration_data.unit_grad';
f_name = sprintf('unit_grad_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, unit_grad(:)','double');

newRgbPmat = iteration_data.newRgbPmat';
f_name = sprintf('next_p_matrix_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, newRgbPmat(:)','double');

newKrgb = iteration_data.newKrgb';
f_name = sprintf('next_Krgb_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, newKrgb(:)','double');

cost = iteration_data.cost;
f_name = sprintf('cost_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, cost,'double');

newCost = iteration_data.newCost;
f_name = sprintf('next_cost_iteration_%d_%d',iteration_data.cycle,iteration_data.iterCount);  
OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, newCost,'double');

end

