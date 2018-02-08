function [err] = calcDelayFineError(img)

errStat = Validation.edgeTrans(double(img));
err = errStat.vertMean;

end

