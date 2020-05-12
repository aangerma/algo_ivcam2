function [newParams, newCost, iterCount] = optimizeParameters(frame,params, outputBinFilesPath)
   
iterCount = 0;
notConverged = 1;
while notConverged && iterCount < params.maxOptimizationIters
    iterCount = iterCount + 1;
    % Calculate gradients
    [cost, gradStruct, iteration_data] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);    
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
        disp(['Final Cost  = ' num2str(newCost)]);
    end
    % Change in cost
    if norm(newCost-cost) < params.minCostDelta
%         disp('Optimization converged');
%         disp('Criteria - Small change in cost');
        notConverged = 0;
        disp(['Final Cost  = ' num2str(newCost)]);
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
disp(['Fx  = ' num2str(newParams.Krgb(1,1))]);
disp(['Fy  = ' num2str(newParams.Krgb(2,2))]);
disp(['ppx  = ' num2str(newParams.Krgb(1,3))]);
disp(['ppy  = ' num2str(newParams.Krgb(2,3))]);

disp('rot  = ');
disp(num2str(newParams.Rrgb(1,1)));
disp(num2str(newParams.Rrgb(2,1)));
disp(num2str(newParams.Rrgb(3,1)));
disp(num2str(newParams.Rrgb(1,2)));
disp(num2str(newParams.Rrgb(2,2)));
disp(num2str(newParams.Rrgb(3,2)));
disp(num2str(newParams.Rrgb(1,3)));
disp(num2str(newParams.Rrgb(2,3)));
disp(num2str(newParams.Rrgb(3,3)));

disp('trans  = ');
disp(num2str(newParams.Trgb(1,1)));
disp(num2str(newParams.Trgb(2,1)));
disp(num2str(newParams.Trgb(3,1)));
end

function dbg = collectDebugData(frame,params,newRgbPmat,stepSize)
    [uvMapPrev,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
    [uvMapPost,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,newRgbPmat,params.Krgb,params.rgbDistort);
    dbg.movement = mean(sqrt(sum((uvMapPrev-uvMapPost).^2,2)));
    dbg.stepSize = stepSize;
end