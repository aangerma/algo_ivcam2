function [newParams,newCost,convergedReason] = optimizeParametersP(frame,params,outputBinFilesPathStruct)

iterCount = 0;
notConverged = 1;
convergedReason = 3; % LRS addition

saveIterData = false;
if exist('outputBinFilesPathStruct','var') && ~isempty(outputBinFilesPathStruct)
    saveIterData = true;
end
    
while notConverged && iterCount < params.maxOptimizationIters
    iterCount = iterCount + 1;
    % Calculate gradients
    if saveIterData
        [cost,gradStruct,iteration_data] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);
    else
        [cost,gradStruct] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);
    end
    
    % Find the step
    [stepSize,newRgbPmat,newKrgb,newRrgb,newTrgb,newCost,unitGrad,grad,grads_norm,norma,BacktrackingLineIterCount,t]  = OnlineCalibration.aux.myBacktrackingLineSearchP(frame,params,gradStruct);%pi()/180
       
    % change in rgbPMat / todo -XY
    if norm(newRgbPmat-params.rgbPmat) < params.minRgbPmatDelta
%         disp('Optimization converged');
%         disp('Criteria - Small movement in rgbPmat');
        notConverged = 0;
        convergedReason = 1; % LRS addition
    end
    % Change in cost
    if norm(newCost-cost) < params.minCostDelta
%         disp('Optimization converged');
%         disp('Criteria - Small change in cost');
        notConverged = 0;
        if convergedReason == 3 % LRS addition
            convergedReason = 2;
        end   
    end
    
    if saveIterData %LRS
        % Check stopping criteria
        iteration_data.cycle = outputBinFilesPathStruct.cycle;
        iteration_data.norma = norma;
        iteration_data.iterCount = iterCount;
        iteration_data.grad = gradStruct;
        iteration_data.unit_grad = unitGrad;
        iteration_data.normalized_grads = grad;
        iteration_data.grads_norm = grads_norm;
        iteration_data.newRgbPmat = newRgbPmat;
        iteration_data.newCost = newCost;
        iteration_data.BacktrackingLineIterCount = BacktrackingLineIterCount;
        iteration_data.t = t;
        saveIterationData(outputBinFilesPathStruct.path, iteration_data);
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