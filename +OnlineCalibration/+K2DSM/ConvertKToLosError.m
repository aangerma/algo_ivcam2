function [losShift, losScaling] = ConvertKToLosError(data, optK)
    
    % K changes
    fxScaling = double(optK(1,1)/data.origK(1,1));
    fyScaling = double(optK(2,2)/data.origK(2,2));
    pxShift = double(optK(1,3)-data.origK(1,3));
    pyShift = double(optK(2,3)-data.origK(2,3));
    
    % shift reconstruction
    losShift = data.shiftRatioMat\[pxShift; pyShift]; % pseudo-inverse
    
    % scaling ratio optimization
    focalScaling = [fxScaling, fyScaling];
    coarseGrid = [-0.0250, -0.0125, 0, 0.0125,0.0250];
    fineGrid = [-0.0150, -0.0075, 0, 0.0075, 0.0150];
    [yScalingGrid, xScalingGrid] = ndgrid(1+coarseGrid, 1+coarseGrid);
    optScaling = RunScalingOptimizationStep(data, losShift, [xScalingGrid(:), yScalingGrid(:)], focalScaling, false);
    [yScalingGrid, xScalingGrid] = ndgrid(optScaling(2)+fineGrid, optScaling(1)+fineGrid);
    losScaling = RunScalingOptimizationStep(data, losShift, [xScalingGrid(:), yScalingGrid(:)], focalScaling, false);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function optScaling = RunScalingOptimizationStep(data, losShift, scalingGrid, focalScaling, plotFlag)
    
    % calculating distance between model-based change and observed change in focal lengths
    optK = OnlineCalibration.K2DSM.OptimizeKUnderLosError(data, scalingGrid, losShift);
    fxScalingOnGrid = squeeze(optK(1,1,:))/data.origK(1,1);
    fyScalingOnGrid = squeeze(optK(2,2,:))/data.origK(2,2);
    errL2 = sqrt((fxScalingOnGrid-focalScaling(1)).^2+(fyScalingOnGrid-focalScaling(2)).^2);
    
    % quadratic approximation
    sgMat = double([scalingGrid(:,1).^2, scalingGrid(:,2).^2, scalingGrid(:,1).*scalingGrid(:,2), scalingGrid(:,1), scalingGrid(:,2), ones(size(scalingGrid,1),1)]);
    quadCoef = (sgMat'*sgMat)\(sgMat'*double(errL2)); % pseudo-inverse
    A = [quadCoef(1), quadCoef(3)/2; quadCoef(3)/2, quadCoef(2)];
    b = [quadCoef(4); quadCoef(5)];
    optScaling = -(A\b)/2; % pseudo-inverse
    
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

