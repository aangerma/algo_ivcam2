function [peak_index,peak_val] = fineCor(fineCorrRange,coarseDownSamplingR,TxFullcode,coarseCorrOffset,cma)
 
    corrSegment = Utils.correlator(cma, flip(TxFullcode), uint32(zeros(size(cma,2),1)), uint16(coarseCorrOffset)*uint16(coarseDownSamplingR), uint16(fineCorrRange));

%% smooth

    mxv=64;
    ker = @(sr) ([sr;mxv-2*sr;sr]);

    cor_seg_fil = corrSegment;
    cor_seg_fil=(pad_array(cor_seg_fil,4,0,'both'));
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = uint32(cor_seg_fil);
    %% find Qfunc
    coarseCorrOffset = uint16(coarseCorrOffset)*uint16(coarseDownSamplingR); 
    coarseCorrOffset = uint16(mod(int32(coarseCorrOffset)-int32(fineCorrRange)  ,int32(length(TxFullcode))));
    coarseCorrOffset = single(coarseCorrOffset) ;   
    [peak_index, peak_val ] = Pipe.DEST.detectPeaks(cor_seg_fil,coarseCorrOffset,1);
end

