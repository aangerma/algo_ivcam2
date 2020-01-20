function [res] = biPolyRansac(points,order,sampleSize,maxDistance,estimationGrid,valueFunc)
% This function performs ransac to fit a polynomial to the data. If there
% are more than 30% outlier points, it performs polynomial fit on them as well. If the second fit fits at leats 30% of the points it is a valid solution as well. It then chooses the solution with the maximal value according to the function handle.

fitPolyFcn = @(points) polyfit(points(:,1),points(:,2),order); % fit function using polyfit
evalLineFcn = @(model, points) sqrt(sum((points(:, 2) - polyval(model, points(:,1))).^2,2));% distance evaluation function

[~,inlierIdx] = ransac(points,fitPolyFcn,evalLineFcn,sampleSize,maxDistance);
inlierPoints = points(inlierIdx,:);
modelInliers = polyfit(inlierPoints(:,1),inlierPoints(:,2),order);

otherPoints = points(~inlierIdx,:);

compare2models = 0;
if (size(otherPoints,1) >= size(points,1)*0.3) && (size(otherPoints,1) >= sampleSize)
    [~,inlierIdx] = ransac(otherPoints,fitPolyFcn,evalLineFcn,sampleSize,maxDistance);
    otherPoints = otherPoints(inlierIdx,:);
    otherModel = polyfit(otherPoints(:,1),otherPoints(:,2),order);
    if size(otherPoints,1) >= size(points,1)*0.3
       compare2models = 1; 
    end
end

res.points = points;
if compare2models
    opt1 = polyval(modelInliers,estimationGrid);
    opt2 = polyval(otherModel,estimationGrid);
    if valueFunc(opt1) > valueFunc(opt2)
        res.minMaxDSMAngExtrap = opt1;
        res.inlierPts = inlierPoints;
    else
        res.minMaxDSMAngExtrap = opt2;
        res.inlierPts = otherPoints;
    end
else
    res.minMaxDSMAngExtrap = polyval(modelInliers,estimationGrid);
    res.inlierPts = inlierPoints;
end




end

