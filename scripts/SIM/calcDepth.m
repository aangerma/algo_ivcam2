function [depth] = calcDepth(corrSegment,corrOffset, regs)

%% smooth
mxv=64;
ker = @(sr) ([sr;mxv-2*sr;sr]);

cor_seg_fil = corrSegment;
cor_seg_fil=(pad_array(cor_seg_fil,4,0,'both'));
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(1)), 'valid'),-6);
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(2)), 'valid'),-6);
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(3)), 'valid'),-6);
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(4)), 'valid'),-6);
cor_seg_fil = uint32(cor_seg_fil);
%%
corrOffset = uint16(corrOffset)*uint16( 2 ^ double(regs.DEST.decRatio));
corrOffset = uint16(mod(int32(corrOffset)-int32(regs.DEST.fineCorrRange)  ,int32(regs.GNRL.tmplLength)));

corrOffset = single(corrOffset)-1 ;

[peak_index, peak_val ] = Pipe.DEST.detectPeaks(cor_seg_fil,corrOffset,regs.MTLB.fastApprox(2));
%% quantize max_peak

maxPeakMaxVal = (2^6-1);%hard coded

peak_val_norm  = uint8(min(maxPeakMaxVal,bitshift(peak_val*regs.DEST.maxvalDiv,-14)-regs.DEST.maxvalSub));

%% Calculate round trip distance
roundTripDistance = peak_index .* map(regs.DEST.sampleDist, 1);
%% rtd2depth
% depth=Pipe.DEST.rtd2depth(roundTripDistance,regs);
rtd_= roundTripDistance- regs.DEST.txFRQpd(1);

depth = (0.5*(rtd_.^2 - regs.DEST.baseline2))./(rtd_ - regs.DEST.baseline.*0);

end

