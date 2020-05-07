function [losShift, losScaling] = ConvertKToLosError(data, isValidPix, origK, optK)
   
    % K changes
    fxScaling = double(optK(1,1)/origK(1,1));
    fyScaling = double(optK(2,2)/origK(2,2));
    pxShift = double(optK(1,3)-origK(1,3));
    pyShift = double(optK(2,3)-origK(2,3));
    
    % shift reconstruction
    shiftRatioMat = double([mean(data.Lxx(isValidPix)), mean(data.Lxy(isValidPix)); mean(data.Lyx(isValidPix)), mean(data.Lyy(isValidPix))]);
    losShift = shiftRatioMat\[pxShift; pyShift];
    
    % pixel-to-LOS mapping
    losX = data.losX(isValidPix(:));
    losY = data.losY(isValidPix(:));
    vertices = data.vertices(isValidPix(:),:);
    
    % scaling ratio optimization
    focalScaling = [fxScaling, fyScaling];
    coarseGrid = (-0.025:0.0125:0.025);
    fineGrid = (-0.015:0.0075:0.015);
    [yScalingGrid, xScalingGrid] = ndgrid(1+coarseGrid, 1+coarseGrid);
    optScaling = RunScalingOptimizationStep(vertices, origK, data.xPixInterpolant, data.yPixInterpolant, [losX, losY], [xScalingGrid(:), yScalingGrid(:)], losShift, focalScaling, false);
    [yScalingGrid, xScalingGrid] = ndgrid(optScaling(2)+fineGrid, optScaling(1)+fineGrid);
    losScaling = RunScalingOptimizationStep(vertices, origK, data.xPixInterpolant, data.yPixInterpolant, [losX, losY], [xScalingGrid(:), yScalingGrid(:)], losShift, focalScaling, false);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function optScaling = RunScalingOptimizationStep(vertices, origK, xPixInterpolant, yPixInterpolant, origLos, scalingGrid, losShift, focalScaling, plotFlag)
    
    errPolyCoef = cat(3, [scalingGrid(:,1), losShift(1)*ones(size(scalingGrid,1),1)], [scalingGrid(:,2), losShift(2)*ones(size(scalingGrid,1),1)]);
    optK = OnlineCalibration.K2DSM.OptimizeKUnderLosError(vertices, xPixInterpolant, yPixInterpolant, origLos, errPolyCoef);
    fxScalingOnGrid = squeeze(optK(1,1,:))/origK(1,1);
    fyScalingOnGrid = squeeze(optK(2,2,:))/origK(2,2);
    errL2 = sqrt((fxScalingOnGrid-focalScaling(1)).^2+(fyScalingOnGrid-focalScaling(2)).^2);
    
    sf = fit(scalingGrid, double(errL2), 'poly22');
    A = [sf.p20, sf.p11/2; sf.p11/2, sf.p02];
    b = [sf.p10; sf.p01];
    optScaling = -(A\b)/2;
    
    [~, indOnGrid] = min(errL2);
    if any(eig(A)<=0) || (any([-1,1].*optScaling(1)>[-1,1].*minmax(vec(scalingGrid(:,1))')) || any([-1,1].*optScaling(2)>[-1,1].*minmax(vec(scalingGrid(:,2))'))) % non-convex or optimum out-of-bounds
        optScaling = scalingGrid(indOnGrid,:);
    end

    if plotFlag
        figure, plot(sf, scalingGrid, errL2)
        hold on, plot3(optScaling(1), optScaling(2), feval(sf, optScaling(1), optScaling(2)), 'pr', 'markerfacecolor', 'y')
        grid on, xlabel('x scaling'), ylabel('y scaling'), title('L_2 error')
    end
    
end

