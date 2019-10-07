function [zValue] = calculateZ(coarseDownSamplingR,fineCorrRange,sample_dist,system_delay,TxFullcode,cma)
%% coarse correlation
[corrOffset] = coarseCor(TxFullcode,coarseDownSamplingR,cma);

%% fine correlation
[peak_index,~] = fineCor(fineCorrRange,coarseDownSamplingR,TxFullcode,corrOffset,cma);

%%
max_dist=sample_dist*length(TxFullcode);

roundTripDistance = peak_index .* sample_dist;
zValue = mod(roundTripDistance-system_delay,max_dist)';

end

