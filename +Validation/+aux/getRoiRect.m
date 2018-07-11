function [mask] = getRoiRect(imgSize, params)

if (~exist('params','var') || ~isfield(params, 'roi'))
    roi = 0.8;
else
    roi = params.roi;
end

if (length(roi) == 1)
    roiMargin = (1 - roi) / 2;
    r = [imgSize(2)*roiMargin+1 imgSize(1)*roiMargin+1 imgSize(2)*roi imgSize(1)*roi];
else
    r = params.roi;
end

roiV = round(r(2)):round(r(2)+r(4)-1);
roiH = round(r(1)):round(r(1)+r(3)-1);

mask = zeros(imgSize, 'logical');
mask(roiV, roiH) = true;

end

