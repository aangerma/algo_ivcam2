function err = auto_corr(code,noise,dec,to_plot,shrink,shift,shrink_pos)
%     shrink,shift,shrink_pos
    full_code=repmat(code,8,1);
    full_code=full_code(:);
    dec_code=full_code(1:dec:end);
    
    full_input=full_code;
    for i=1:length(full_input)
       if rand > 1-noise
          full_input(i)=1-full_input(i); 
       end
    end
    
    if shrink>0
        full_input=[full_input(1:shrink_pos-shrink-1);
                    or(full_input(shrink_pos-shrink:shrink_pos),full_input(shrink_pos:shrink_pos+shrink));
                    full_input(shrink_pos+shrink+1:end);
                    full_input(1:shrink)];
    elseif shrink<0
        full_input=[full_input(1:shrink_pos);
                    zeros(-shrink,1);
                    full_input(shrink_pos+1:end+shrink)];
    end      
    
    full_input=circshift(full_input,shift);
    dec_input=full_input(1:dec:end);
%     corr=cconv(code,flip(input));
    
    cor_dec = Utils.correlator(uint16(dec_input), uint8(dec_code));
    [~, maxIndDec] = max(cor_dec);
    corrOffset = uint8(maxIndDec-1);
    corrOffset = permute(corrOffset,[2 1]);

    corrSegment = Utils.correlator(full_input, full_code, uint32(0), uint16(corrOffset)*uint16(dec), uint16(16));

    mxv=64;
    ker = @(sr) ([sr;mxv-2*sr;sr]);

    cor_seg_fil = corrSegment;
    cor_seg_fil=(pad_array(cor_seg_fil,4,0,'both'));
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker(21), 'valid'),-6);
    cor_seg_fil = uint32(cor_seg_fil);

    corrOffset = uint16(corrOffset)*uint16(dec); 
    corrOffset = uint16(mod(int32(corrOffset)-int32(16)  ,int32(512)));
    corrOffset = single(corrOffset) ;   
    [peak_index, ~ ] = Pipe.DEST.detectPeaks(cor_seg_fil,corrOffset,1);
    
    err=min(abs(mod(peak_index,512)-1-shift),abs(mod(peak_index,512)-1-shift+shrink));
   
    if to_plot
        corr=double(cor_dec);

        corr=corr/max(corr(:)); 
        plot(corr);
%         title(err);
        hold on
        plot(ceil(shift/dec+1),corr(ceil(shift/dec+1)),'o');
        s=shift-shrink;
        plot(ceil(s/dec+1),corr(ceil(s/dec+1)),'o');
        axis([-inf inf 0 1]);
        hold off
    end
         
end

