function [xLosScaling, yLosScaling] = CalcUnderlyingLosScaling(scalingRatioMat, fxScaling, fyScaling)
    
    % notations
    Kxx = scalingRatioMat(1,1);
    Kxy = scalingRatioMat(1,2);
    Kyx = scalingRatioMat(2,1);
    Kyy = scalingRatioMat(2,2);
    
    % substitution
    fx = fxScaling-1;
    fy = fyScaling-1;
    
    % quadratic equation coefficients
    A = Kxx*Kyx*(Kxy-Kyy);
    B = Kyy*(Kyx*fx-Kxx) - Kxy*(Kxx*fy-Kyx);
    C = Kyy*fx - Kxy*fy;
    
    % solution
    sx = (-B+[-1,1]*sqrt(B^2-4*A*C))/(2*A);
    [~, ind] = min(abs(sx));
    sx = sx(ind);
    sy = (fx-Kxx*sx) / (Kxy*(1+Kxx*sx));
    
    % substitution
    xLosScaling = sx+1;
    yLosScaling = sy+1;
    
end