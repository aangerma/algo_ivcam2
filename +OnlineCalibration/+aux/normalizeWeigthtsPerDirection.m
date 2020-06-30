function weightsNormed = normalizeWeigthtsPerDirection(weights,directions,validDirections,edgesPerDirection)
%NORMALIZEWEIGTHTSPERDIRECTION 
% Normalizes the weights so that the valid
% directions have the same total wights so they can balance each other.
% The invalid directions gets the mean weight of the good ones. Unless their sum is larger than that of a good direction, in this case they get the weight that ensures that the invalid directions have exactly the same weight as the good directions.


if sum(validDirections) == 0 % This condition can't be met in LRS (since we passed input validity), it can only happen in matlab for deveopment purpose
    weightsNormed = weights;
    return;
end



% Normalize weights of valid directions so their sum is 1
newWeightPerDir = zeros(1,numel(validDirections));
for i = 1:numel(validDirections)
    if validDirections(i)
       newWeightPerDir(i) = 1./edgesPerDirection(i);
    end
end
% Calculate the average weight of valid edges
avgValidWeight = mean(newWeightPerDir(validDirections));

% Clip the weight so the total sum won't be larger than 1
newWeightPerDir(~validDirections) = min(avgValidWeight,1/sum(edgesPerDirection(~validDirections)));

% Set the new weights, we will keep the original sum of weights through this normalization
tmpWeightsNormed = newWeightPerDir(directions)';
weightsNormed = tmpWeightsNormed./sum(tmpWeightsNormed)*sum(weights);
end

