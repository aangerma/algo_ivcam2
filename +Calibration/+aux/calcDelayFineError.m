function [err] = calcDelayFineError(img)

errStat = edgeTrans(double(img));
err = errStat.vertMean;

end

