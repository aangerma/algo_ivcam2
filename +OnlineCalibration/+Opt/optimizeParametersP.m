function [newParams,newCost,iterCount] = optimizeParametersP(frame,params,outputBinFilesPath,cycle)

iterCount = 0;
notConverged = 1;
while notConverged && iterCount < params.maxOptimizationIters
    iterCount = iterCount + 1;
    % Calculate gradients
    %[cost,gradStruct] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);
    [cost,gradStruct,iteration_data] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);
    
    % Find the step
    %[stepSize,newRgbPmat,newKrgb,newRrgb,newTrgb,newCost] = OnlineCalibration.aux.myBacktrackingLineSearchP(frame,params,gradStruct);%pi()/180
    [stepSize,newRgbPmat,newKrgb,newRrgb,newTrgb,newCost,unitGrad,grad,grads_norm,norma,BacktrackingLineIterCount,t]  = OnlineCalibration.aux.myBacktrackingLineSearchP(frame,params,gradStruct);%pi()/180
    
    % Check stopping criteria
    iteration_data.norma = norma;
    iteration_data.iterCount = iterCount;
    iteration_data.cycle = cycle;
    iteration_data.grad = gradStruct;
    iteration_data.unit_grad = unitGrad;
    iteration_data.normalized_grads = grad;
    iteration_data.grads_norm = grads_norm;
    iteration_data.newRgbPmat = newRgbPmat;
    iteration_data.newCost = newCost;
    iteration_data.BacktrackingLineIterCount = BacktrackingLineIterCount;
    iteration_data.t = t;
    
    saveIterationData(outputBinFilesPath, iteration_data);
    % change in rgbPMat / todo -XY
    if norm(newRgbPmat-params.rgbPmat) < params.minRgbPmatDelta
%         disp('Optimization converged');
%         disp('Criteria - Small movement in rgbPmat');
        notConverged = 0;
    end
    % Change in cost
    if norm(newCost-cost) < params.minCostDelta
%         disp('Optimization converged');
%         disp('Criteria - Small change in cost');
        notConverged = 0;
    end
    
    dbg(iterCount) = collectDebugData(frame,params,newRgbPmat,stepSize); % Collect debug for RnD, do not implement in LRS
    
    params.rgbPmat = newRgbPmat;
    params.Krgb = newKrgb;
    params.Rrgb = newRrgb;
    params.Trgb = newTrgb;
end

% Update new Params
newParams = params;


end

function dbg = collectDebugData(frame,params,newRgbPmat,stepSize)
    [uvMapPrev,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort,params);
    [uvMapPost,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newRgbPmat,params.Krgb,params.rgbDistort,params);
    dbg.movement = mean(sqrt(sum((uvMapPrev-uvMapPost).^2,2)));
    dbg.stepSize = stepSize;
end