function [err] = calcDelayFineError(img)

errStat = Validation.edgeTrans(double(img), 7, [9 13]);
err = errStat.vertMean;

end

