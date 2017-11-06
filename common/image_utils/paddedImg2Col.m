function [vecImg,centralP] = paddedImg2Col(imgIn,winSze)
    
    padSize = (winSze-1)    /2;
    imgIn = double(imgIn);     imgPadded = padarray(imgIn,padSize,'replicate','both');
    vecImg = Utils.im2col_fast(imgPadded,winSze);
    centralIndex = winSze(2)*(winSze(1)-1)/2+(winSze(2)-1)/2+1;
    centralP = vecImg(centralIndex,:);
end