function [wIm,W,validMask] = calcDepthWeights(zIm,iIm,options)
    Ez = calcEImage(zIm,options);
    Ei = calcEImage(iIm,options);
    wIm = (Ei>options.gradITh ).*Ez;
    wIm(wIm<options.gradZTh) = 0;
    validMask = wIm>0;
    W = wIm(validMask);
end