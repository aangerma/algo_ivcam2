function [ maskingRegs ] = maskDistances(regs,distRange )
%MASKDISTANCES receieved regs that describe the camera and a range of distances
% it produces the value of the corase masking that will filter that
% distance


delays = regs.DEST.txFRQpd(1) + max(regs.DEST.txPWRpd) + max(regs.DEST.rxPWRpd) - regs.DEST.tmptrOffset;
minRange = distRange(1);

fullRange = regs.DEST.ambiguityRTD(1);
rtdPerCoarseSample = (0:single(regs.GNRL.codeLength*regs.FRMW.coarseSampleRate-1))*fullRange/single(regs.GNRL.codeLength*regs.FRMW.coarseSampleRate);
rtdPerCoarseSampleAfterDelay = mod(rtdPerCoarseSample - delays,fullRange);

rangePerCoarseSampleAfterDelay = rtdPerCoarseSampleAfterDelay/2;
dr = rtdPerCoarseSample(2)/2;

find(abs(minRange-rangePerCoarseSampleAfterDelay)<=dr/2,1)


end

