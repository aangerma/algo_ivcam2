function [rxregs] = rxDelay2regs(RXDelay,regs)
% TODO - if regs has a non-default gamma configuration (Not during capturing! I assume captures were done with default!), we need to apply
% gamma to the IR values and fix the graph 

% Assumes RX delay in mm
% Assumes no digg gamma is configured
rxregs.DEST.rxPWRpdScale = single([1 1 1 1]);

% rxLUTindex = uint16(bitshift(uint64(ir)*uint64(regs.DEST.rxPWRpdLUTfactor)+2^15,-16));
rxregs.DEST.rxPWRpdLUTfactor = uint32(2^22/4095);% So the IR index is between 0 and 64

RXDelay(RXDelay==0) = nan;
% Quantize the IR into 65 values
irVals = linspace(0,4095,65);
halfEdge = irVals(2)/2;
% for each IR value, get the indices for the IR in its bin:
irCell = arrayfun(@(x) ceil(x-halfEdge):floor(x+halfEdge) ,irVals,'UniformOutput',0);
% For each cell, remove negative indices, and indices above 4095 and add 1.
irCell = cellfun(@(x) x(logical((x>=0).*(x<=4095)))+1,irCell,'UniformOutput',0);
rxCell = cellfun(@(x) RXDelay(uint16(x)),irCell,'UniformOutput',0);
rxCell = cellfun(@(x) mean(x,2,'omitnan'),rxCell,'UniformOutput',0);

rx = cat(1,rxCell{:});
rx = rx - mean(rx,'omitnan');
firstNonNanIdx = find(~isnan(rx), 1);
rx(1:firstNonNanIdx) = rx(firstNonNanIdx);

% plot(irVals,rx),hold on, plot(rtdDelay)
rxregs.DEST.rxPWRpd = single(rx);
end