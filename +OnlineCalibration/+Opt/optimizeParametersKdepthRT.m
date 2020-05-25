function [newParams,newCost] = optimizeParametersKdepthRT(frame,params)

iterCount = 0;
notConverged = 1;
while notConverged && iterCount < params.maxOptimizationIters
    iterCount = iterCount + 1;
    % Calculate gradients
    [cost,gradStruct] = OnlineCalibration.Opt.calcCostAndGrad(frame,params);
    % Find the step
    [stepSize,newKRTP,newCost] = OnlineCalibration.aux.myBacktrackingLineSearchKdepthRT(frame,params,gradStruct);%pi()/180
    % Check stopping criteria
    
    % change in rgbPMat / todo -XY
    newRgbPmat = newKRTP.P;
%     if norm(newRgbPmat-params.rgbPmat) < params.minRgbPmatDelta
% %         disp('Optimization converged');
% %         disp('Criteria - Small movement in rgbPmat');
%         notConverged = 0;
%     end
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
    params.Kdepth = newKRTP.Kdepth;
    [params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
    
end

% Update new Params
newParams = params;


end

function dbg = collectDebugData(frame,params,newRgbPmat,stepSize)
    [uvMapPrev,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
    vertices = ([frame.xim,frame.yim,ones(size(frame.yim))] * pinv(params.Kdepth)').*frame.vertices(:,3);
    [uvMapPost,~,~] = OnlineCalibration.aux.projectVToRGB(vertices,newRgbPmat,params.Krgb,params.rgbDistort);
    dbg.movement = mean(sqrt(sum((uvMapPrev-uvMapPost).^2,2)));
    dbg.stepSize = stepSize;
end