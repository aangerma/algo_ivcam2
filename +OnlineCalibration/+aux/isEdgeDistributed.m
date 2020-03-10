function [isDistributed] = isEdgeDistributed(weights,sectionMap,params)
isDistributed = true;
meanWeightsPerSection = zeros(params.numSectionsV*params.numSectionsH,1);
for ix = 1:params.numSectionsV*params.numSectionsH
    meanWeightsPerSection(ix) = nanmean(weights(sectionMap == ix-1));
end
minMaxRatio = min(meanWeightsPerSection)/max(meanWeightsPerSection);
if minMaxRatio < params.edgeDistributMinMaxRatio
    isDistributed = false;
    fprintf('isEdgeDistributed: Ratio between min and max is too small: %0.5f, threshold is %0.5f\n',minMaxRatio, params.edgeDistributMinMaxRatio);
    return;
end

if any(meanWeightsPerSection< params.minWeightedEdgePerSection)
    isDistributed = false;
    printVals = num2str(meanWeightsPerSection(1));
    for k = 2:numel(meanWeightsPerSection)
        printVals = [printVals,',',num2str(meanWeightsPerSection(k))];
    end
    disp(['isEdgeDistributed: weighted edge per section is too low: ' printVals ', threshold is ' num2str(params.minWeightedEdgePerSection)]);
    return;
end
end

