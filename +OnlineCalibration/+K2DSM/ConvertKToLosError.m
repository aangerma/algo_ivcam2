function losScaling = ConvertKToLosError(data, optK)
    
    % K changes
    fxScaling = double(optK(1,1)/data.origK(1,1));
    fyScaling = double(optK(2,2)/data.origK(2,2));
    
    % scaling ratio optimization
    focalScaling = [fxScaling, fyScaling];
    coarseGrid = [-1, -0.5, 0, 0.5, 1]*data.maxScalingStep;
    fineGrid = [-1, -0.5, 0, 0.5, 1]*0.6*data.maxScalingStep; % intentionally spans more than 1 coarse grid resolution
    [yScalingGrid, xScalingGrid] = ndgrid(data.lastLosScaling(2)+coarseGrid, data.lastLosScaling(1)+coarseGrid); % search around last estimated scaling
    optScaling = RunScalingOptimizationStep(data, [xScalingGrid(:), yScalingGrid(:)], focalScaling, false);
    [yScalingGrid, xScalingGrid] = ndgrid(optScaling(2)+fineGrid, optScaling(1)+fineGrid);
    losScaling = RunScalingOptimizationStep(data, [xScalingGrid(:), yScalingGrid(:)], focalScaling, false);
    
    % forcing maximal allowed scaling step w.r.t. last AC event
    maxStepWithMargin = 1.01*data.maxScalingStep; % to avoid numerical issues
    losScaling(1) = min(max(losScaling(1), data.lastLosScaling(1)-maxStepWithMargin), data.lastLosScaling(1)+maxStepWithMargin);
    losScaling(2) = min(max(losScaling(2), data.lastLosScaling(2)-maxStepWithMargin), data.lastLosScaling(2)+maxStepWithMargin);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function optScaling = RunScalingOptimizationStep(data, scalingGrid, focalScaling, plotFlag)
    
    % calculating distance between model-based change and observed change in focal lengths
    optK = OnlineCalibration.K2DSM.OptimizeKUnderLosError(data, scalingGrid);
    fxScalingOnGrid = squeeze(optK(1,1,:))/data.origK(1,1);
    fyScalingOnGrid = squeeze(optK(2,2,:))/data.origK(2,2);
    errL2 = sqrt((fxScalingOnGrid-focalScaling(1)).^2+(fyScalingOnGrid-focalScaling(2)).^2);
    
    % quadratic approximation
    sgMat = double([scalingGrid(:,1).^2, scalingGrid(:,2).^2, scalingGrid(:,1).*scalingGrid(:,2), scalingGrid(:,1), scalingGrid(:,2), ones(size(scalingGrid,1),1)]);
    quadCoef = OnlineCalibration.K2DSM.DirectInv(sgMat'*sgMat)*(sgMat'*double(errL2)); % direct implementation of Matlab's solver: (sgMat'*sgMat)\(sgMat'*double(errL2))
    A = [quadCoef(1), quadCoef(3)/2; quadCoef(3)/2, quadCoef(2)];
    b = [quadCoef(4); quadCoef(5)];
    optScaling = -OnlineCalibration.K2DSM.DirectInv(A)*b/2; % direct implementation of Matlab's solver: -(A\b)/2
    
    % sanity check
    isPosDef = (quadCoef(1)+quadCoef(2))>0 && (quadCoef(1)*quadCoef(2)-quadCoef(3)^2/4)>0;
    isWithinLims = (optScaling(1) > min(scalingGrid(:,1))) && (optScaling(1) < max(scalingGrid(:,1))) && (optScaling(2) > min(scalingGrid(:,2))) && (optScaling(2) < max(scalingGrid(:,2)));
    if ~isPosDef || ~isWithinLims % non-convex or optimum out-of-bounds
        [~, indOnGrid] = min(errL2);
        optScaling = scalingGrid(indOnGrid,:);
    end
    
    % debug plot
    if plotFlag
        figure, plot(sf, scalingGrid, errL2)
        hold on, plot3(optScaling(1), optScaling(2), feval(sf, optScaling(1), optScaling(2)), 'pr', 'markerfacecolor', 'y')
        grid on, xlabel('x scaling'), ylabel('y scaling'), title('L_2 error')
    end
    
end

