function [params] = getAugmentationParams(params)
if ~isfield(params,'augmentOne')
    params.augmentationMaxMovement = 4;
    params.augmentOne = rand(1) < 0.5;
    params.augmentRand01Number = rand(1);
end
end

