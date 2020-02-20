function newParams = optimizeParameters(frame,params)

iterCount = 0;
notConverged = 1;
while notConverged && iterCount < params.maxOptimizationIters
    iterCount = iterCount + 1;
    % Calculate gradients
    [cost,gradStruct] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);
    gradStruct.A(3,:) = 0;
    % Find the step
    [~,newRgbPmat,newCost] = OnlineCalibration.aux.myBacktrackingLineSearchP(frame,params,gradStruct);%pi()/180
    % Check stopping criteria
    
    % change in rgbPMat / todo -XY
    if norm(newRgbPmat-params.rgbPmat) < params.minRgbPmatDelta
        disp('Optimization converged');
        disp('Criteria - Small movement in rgbPmat');
        notConverged = 0;
    end
    % Change in cost
    if norm(newCost-cost) < params.minCostDelta
        disp('Optimization converged');
        disp('Criteria - Small change in cost');
        notConverged = 0;
    end
    params.rgbPmat = newRgbPmat;
    
end

% Update new Params
newParams = params;


end

