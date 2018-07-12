function [mask] = getRoiMask(imgSize, params)

if (params.isRoiRect)
    mask = Validation.aux.getRoiRect(imgSize, params);
else
    mask = Validation.aux.getRoiCircle(imgSize, params);
end

if (params.roiCropRect && ~params.isRoiRect)
    p = Validation.aux.defaultMetricsParams();
    p.isRoiRect = true;
    p.roi = 1 - params.roiCropRect;
    maskCrop = Validation.aux.getRoiRect(imgSize, p);
    mask = and(mask, maskCrop);
end


end

