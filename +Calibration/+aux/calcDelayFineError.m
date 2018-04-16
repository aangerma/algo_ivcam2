function [err] = calcDelayFineError(img)

res = Validation.edgeTrans(double(img), 9, [9 13]);
err = res.vertMean;

end

