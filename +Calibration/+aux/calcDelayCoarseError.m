function [err] = calcDelayCoarseError(img)

img = double(img);
imgGrad = diff(img, 1, 2);

img0 = img(:,1:end-1);
img1 = img(:,2:end);

gradMask = and(img0 ~= 0, img1 ~= 0);

normGrad = imgGrad ./ max(img0, img1);

g2 = normGrad.^2;
err = sum(g2(gradMask ~= 0)); % / sum(gradMask(:));

end

