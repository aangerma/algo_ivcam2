function [err] = calcDelayFineError(img)

errStat = Validation.edgeTrans(double(img), 9, [9 13]);
err = errStat.vertMean;

end

