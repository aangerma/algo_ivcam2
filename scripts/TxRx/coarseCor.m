function [corrOffset,zValueFromCoarseOnly] = coarseCor(TxFullcode,coarseDownSamplingR,cma,sample_dist,max_dist,system_delay)
    ccode = reshape(TxFullcode, coarseDownSamplingR, double(length(TxFullcode))/coarseDownSamplingR,1);
    ccode = permute(sum(uint32(ccode),1, 'native'),[2 1]);
    ccode = repmat(ccode,1,64);
    cma_dec = reshape(cma, coarseDownSamplingR, double(length(TxFullcode))/coarseDownSamplingR, size(cma,2));
    cma_dec = permute(sum(uint32(cma_dec),1, 'native'),[2 3 1]);

    cor_dec = Utils.correlator(uint16(cma_dec), uint8(flip(ccode)));
    [~, maxIndDec] = max(cor_dec);
    corrOffset = uint8(maxIndDec-1);
    corrOffset = permute(corrOffset,[2 1]);
     roundTripDistance = single( uint16(corrOffset)*uint16(coarseDownSamplingR)) .* sample_dist;
     zValueFromCoarseOnly = mod(roundTripDistance-system_delay,max_dist)';
end

