function [wIm,W,validMask] = calcDepthWeights(zIm,iIm,options)
    Ez = OnlineCalibration.aux.calcEImage(zIm,options);
    Ei = OnlineCalibration.aux.calcEImage(iIm,options);
    wIm = (Ei>options.gradITh ).*Ez;
    wIm(wIm<options.gradZTh) = 0;
    validMask = wIm>0;
    W = wIm(validMask);
end