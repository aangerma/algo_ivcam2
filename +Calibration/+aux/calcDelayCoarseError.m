function [err] = calcDelayFineError(img)

img = double(img);
imgGrad = diff(img, 1, 2);
g2 = imgGrad.^2;
err = sum(g2(:));

end

