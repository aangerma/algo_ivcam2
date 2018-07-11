function [mask] = getRoiMask(imgSize, params)

if (~exist('params','var') || ~isfield(params, 'isRoiRect') || ~params.isRoiRect)
    mask = Validation.aux.getRoiCircle(imgSize, params);
else
    mask = Validation.aux.getRoiRect(imgSize, params);
end

end

