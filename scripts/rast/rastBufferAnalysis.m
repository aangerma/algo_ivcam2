% cmac buffer analysis
% run when breakpoint is set at the end of RAST.m

pxindOut  = sub2ind([mRegs.imgVsize,mRegs.imgHsize],pxOut(2,:)+1,pxOut(1,:)+1)';
timestamps = double(fStats.timestamps(pxindOut));

bufferSize = round(double(regs.GNRL.imgVsize));
bufW = ones(bufferSize,1)/double(bufferSize);
timestampsBuffered = conv(timestamps, bufW, 'same');
convRange = bufferSize:(length(timestamps)-3*bufferSize);
timestampsBuffered = timestampsBuffered(convRange);
minPixelTime = min(diff(timestampsBuffered));
avePixelTimeCl = ceil(mean(diff(timestampsBuffered)));
avePixelTimeNS = avePixelTimeCl*1000/double(regs.MTLB.asicRASTclock);

timestamps = timestamps(convRange);

%outRates = avePixelTimeCl-3:avePixelTimeCl+3; % change test rate in clocks here
outRates = 25:1:30; % change test rate in clocks here
rateVsBuffSize = zeros(2,length(outRates));
rateVsBuffSize(1, :) = outRates;
rateVsBuffSize(2, :) = outRates*1000/double(regs.MTLB.asicRASTclock);

iRate = 1;
for outRate = outRates
    outCounter = 0;
    currPx = 1;
    currBufferSize = 0;
    maxTime = max(timestamps)+100*double(regs.GNRL.imgVsize);
    bufSizes = zeros(1, maxTime);
    for t=1:maxTime
        bufSizes(t) = currBufferSize;
        
        if (currPx <= length(timestamps) && t == timestamps(currPx))
            currBufferSize = currBufferSize + 1;
            currPx = currPx + 1;
        end
        if (outCounter == 0)
            if (currBufferSize ~= 0)
                currBufferSize = currBufferSize - 1;
            end
        end
        outCounter = outCounter + 1;
        if (outCounter == outRate)
            outCounter = 0;
        end
    end
    
    rateVsBuffSize(3, iRate) = max(bufSizes);
    iRate = iRate + 1;
end



