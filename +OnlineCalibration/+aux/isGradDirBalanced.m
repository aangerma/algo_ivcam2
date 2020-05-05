function [isBalanced,dirRatio1,perpRatio,dirRatio2,weightsPerDir] = isGradDirBalanced(frame,params)
isBalanced = false;
dirRatio2 = nan;
perpRatio = nan;

weightsPerDir = sum(frame.weights.*(frame.dirPerPixel==[1:4]));

[maxVal,maxIx] = max(weightsPerDir);
ixMatch = mod(maxIx+2,4);
if ixMatch == 0
    ixMatch = 4;
end
if weightsPerDir(ixMatch) < 1e-3 %Don't devide by zero...
    dirRatio1 = 1e6;
else
    dirRatio1 = maxVal/weightsPerDir(ixMatch);
end
if dirRatio1 > params.gradDirRatio
    ixCheck = true(size(weightsPerDir));
    ixCheck([maxIx,ixMatch]) = false;
    [maxValPerp,~] = max(weightsPerDir(ixCheck));
    perpRatio = maxVal/maxValPerp;
    if perpRatio > params.gradDirRatioPerp
        fprintf('isGradDirBalanced: gradient direction is not balanced: %0.5f, threshold is %0.5f\n',dirRatio1, params.gradDirRatio );
        return;
    end
    if min(weightsPerDir(ixCheck)) < 1e-3 %Don't devide by zero...
        fprintf('isGradDirBalanced: gradient direction is not balanced: %0.5f, threshold is %0.5f\n',dirRatio1, params.gradDirRatio );
        dirRatio2 = nan;
        return;
    end
    dirRatio2 = maxValPerp/min(weightsPerDir(ixCheck));
    if dirRatio2 > params.gradDirRatio
        fprintf('isGradDirBalanced: gradient direction is not balanced: %0.5f, threshold is %0.5f\n',dirRatio1, params.gradDirRatio );
        return;
    end
end
isBalanced = true;

end

