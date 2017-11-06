function [ Img ] = im2box( I, filterHeight, filterWidth)

padSize = [(filterHeight-1)/2 (filterWidth-1)/2];
Ip = pad_array(I, padSize, 'replicate', 'both');
Ic = im2col_fast(Ip, [filterHeight filterWidth]);
Img = reshape(Ic, [filterHeight*filterWidth size(I)]); 

end

