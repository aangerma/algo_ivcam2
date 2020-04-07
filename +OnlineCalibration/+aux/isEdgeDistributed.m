function [isDistributed,minMaxRatio,sumWeightsPerSection] = isEdgeDistributed(weights,sectionMap,params)
isDistributed = true;
sumWeightsPerSection = zeros(params.numSectionsV*params.numSectionsH,1);
for ix = 1:params.numSectionsV*params.numSectionsH
    sumWeightsPerSection(ix) = sum(weights(sectionMap == ix-1));
end


minMaxRatio = min(sumWeightsPerSection)/max(sumWeightsPerSection);
if minMaxRatio < params.edgeDistributMinMaxRatio
    isDistributed = false;
    fprintf('isEdgeDistributed: Ratio between min and max is too small: %0.5f, threshold is %0.5f\n',minMaxRatio, params.edgeDistributMinMaxRatio);
    return;
end

if any(sumWeightsPerSection< params.minWeightedEdgePerSection)
    isDistributed = false;
    printVals = num2str(sumWeightsPerSection(1));
    for k = 2:numel(sumWeightsPerSection)
        printVals = [printVals,',',num2str(sumWeightsPerSection(k))];
    end
    disp(['isEdgeDistributed: weighted edge per section is too low: ' printVals ', threshold is ' num2str(params.minWeightedEdgePerSection)]);
    return;
end
end

