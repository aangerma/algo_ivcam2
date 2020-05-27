function [newParams,newCost] = optimizeParameters(frame,params,outputBinFilesPath)

iterCount = 0;
notConverged = 1;
while notConverged && iterCount < params.maxOptimizationIters
    iterCount = iterCount + 1;
    % Calculate gradients
    [cost,gradStruct,iteration_data] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);
    gradStruct.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(gradStruct.xAlpha,gradStruct.yBeta,gradStruct.zGamma);
    
    iteration_data.iterCount = iterCount;
    iteration_data.grad = gradStruct;
    iteration_data.cost = cost;
    
    saveIterationData(outputBinFilesPath, iteration_data);

    fprintf('Cost = %.10d\n', cost);
    % Find the step
    [stepSize,newKRTP,newCost] = OnlineCalibration.aux.myBacktrackingLineSearchKRT(frame,params,gradStruct);
    newRgbPmat = newKRTP.P;
    % Check stopping criteria
    
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
    params.Krgb = newKRTP.Krgb;
    params.Trgb = newKRTP.Trgb;
    params.Rrgb = newKRTP.Rrgb;
    [params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
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