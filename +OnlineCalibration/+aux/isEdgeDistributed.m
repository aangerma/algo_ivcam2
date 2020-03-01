function [isDistributed] = isEdgeDistributed(weights,sectionMap,params)
isDistributed = true;
meanWeightsPerSection = zeros(params.numSectionsV*params.numSectionsH,1);
for ix = 1:params.numSectionsV*params.numSectionsH
    meanWeightsPerSection(ix) = mean(weights(sectionMap == ix-1));
end
minMaxRatio = min(meanWeightsPerSection)/max(meanWeightsPerSection);
if minMaxRatio < params.edgeDistributMinMaxRatio
    isDistributed = false;
    fprintf('isEdgeDistributed: Ratio between min and max is too small: %0.5f, threshold is %0.5f',minMaxRatio, params.edgeDistributMinMaxRatio);
    return;
end

if any(meanWeightsPerSection< params.minWeightedEdgePerSection)
    isDistributed = false;
    fprintf('isEdgeDistributed: weighted edge per section too low: (%8.1f) threshold is %8.1f' ,meanWeightsPerSection,params.edgeDistributMinMaxRatio);
    return;
end
end

