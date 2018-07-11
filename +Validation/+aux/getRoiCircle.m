function [mask] = getRoiCircle(imgSize, params)

if (~exist('params','var') || ~isfield(params, 'roi'))
    roi = 0.8;
else
    roi = params.roi;
end

[Y, X] = ndgrid(1:imgSize(1),1:imgSize(2));
Y = Y - imgSize(1)/2 - 0.5;
X = X - imgSize(2)/2 - 0.5;

R = norm(imgSize/2);
R = R * roi;
R2 = R^2;

mask = (Y.^2 + X.^2) <= R2;

end

