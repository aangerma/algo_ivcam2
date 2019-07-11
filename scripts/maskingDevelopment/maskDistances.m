function [ coarseMask_002,hexVals ] = maskDistancesWithCoarseMasking(regs,delays,distRange )
%MASKDISTANCES receieved regs that describe the camera and a range of distances
% it produces the value of the corase masking that will filter that
% distances. Currently we only support the update of coarse masking 2.


% delays = regs.DEST.txFRQpd(1) + max(regs.DEST.txPWRpd) + max(regs.DEST.rxPWRpd) - regs.DEST.tmptrOffset;
minRange = distRange(1);
maxRange = distRange(2);

fullRange = regs.DEST.ambiguityRTD(1);
rtdPerCoarseSample = (0:single(regs.GNRL.codeLength*regs.FRMW.coarseSampleRate-1))*fullRange/single(regs.GNRL.codeLength*regs.FRMW.coarseSampleRate);

rtdPerCoarseSampleAfterDelay = mod(rtdPerCoarseSample - delays,fullRange);

rangePerCoarseSampleAfterDelay = rtdPerCoarseSampleAfterDelay/2;
dr = rtdPerCoarseSample(2)/2;

indices = [];
for range = [minRange:dr:maxRange,maxRange]
ids = find(abs(range - rangePerCoarseSampleAfterDelay)<1.5*dr | ...
            abs(range + fullRange/2 - rangePerCoarseSampleAfterDelay)<1.5*dr | ...
            abs(range - fullRange/2 - rangePerCoarseSampleAfterDelay)<1.5*dr);
indices = [indices,ids];
end
indices = unique(indices);

maskLength = regs.DCOR.coarseTmplLength;

% What happens in the DCOR (cMask4 is the used mask):
% cMask0 = regs.DCOR.coarseMasking;
% cMask1 = reshape(cMask0,[],3).';
% 
% %cut to wanted size
% cMask2 = cMask1(:,1:maskLength).';
% 
% % due to DCOR HW implementation the registers should be stored in
% % decending order while the first (0) bin is in the last place
% cMask3 = flipud(cMask2);
% cMask4 = circshift(cMask3,[1 0]);
% cMask4(:,1);

cMask4 = ones(maskLength,3);
cMask4(indices,:) = 0;
cMask3 = circshift(cMask4,[-1 0]);
cMask2 = flipud(cMask3);
cMask1 = [cMask2',ones(3,maskLength)];
cMask0 = reshape(cMask1',[],1)';
DCORcoarseMasking = cMask0;
hexVals = binaryVectorToHex(fliplr(reshape(DCORcoarseMasking,32,[])'));
coarseMask_002 = hexVals{3};
coarseMask_002 = hex2dec(coarseMask_002);
end

