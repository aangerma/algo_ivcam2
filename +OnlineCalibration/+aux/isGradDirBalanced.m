function [isBalanced] = isGradDirBalanced(frame,params)
isBalanced = false;
iWeights = frame.zEdgeSupressed>0;
weightIm = frame.zEdgeSupressed;
weightIm(iWeights) = frame.weights;
xVsYdirRatio = sum(weightIm(frame.dirI == 1))/sum(weightIm(frame.dirI == 3));
if xVsYdirRatio < params.gradDirRatio 
    fprintf('isGradDirBalanced: gradient direction is not balanced, x vs. y: %0.5f, threshold is %0.5f\n',xVsYdirRatio, params.gradDirRatio );
    return;
end
if xVsYdirRatio > 1/params.gradDirRatio 
    fprintf('isGradDirBalanced: gradient direction is not balanced, x vs. y: %0.5f, threshold is %0.5f\n',xVsYdirRatio, 1/params.gradDirRatio );
    return;
end
isBalanced = true;

end

