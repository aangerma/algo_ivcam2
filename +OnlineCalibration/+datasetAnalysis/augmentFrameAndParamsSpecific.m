function [frame,params] = augmentFrameAndParamsSpecific(frame,params)
%AUGMENTFRAMEANDPARAMS
% This function randomly choose and insert an error to the scene/parameters
% oneParamAugmentationOption = {'KdepthFx';...
%     'KdepthFy';...
%     'KrgbFx';...
%     'KrgbFy';...
%     'KrgbCx';...
%     'KrgbCy';...
%     'Ralpha';...
%     'Rbeta';...
%     'Rgamma';...
%     'Tx';...
%     'Ty';...
%     'Tz';...
%     'scaleDepthX';...
%     'scaleDepthY';...
%     'offsetDepthX';...
%     'offsetDepthY';...
%     };
if params.augmentationMaxMovement == 0
    return;
end
augmentationMaxMovement = params.augmentationMaxMovement;
if ~isfield(params,'randPixMovement')
    randPixMovement = 2*augmentationMaxMovement*rand(1) - augmentationMaxMovement;
    
else
    randPixMovement = params.randPixMovement;
end

% randPixMovement = -2.951082343655958;
% randPixMovement = 2.317838864206094;
% randPixMovement = -4;
randPixMovement =  4;

params.randPixMovement = randPixMovement;
paramAugmentation = params.augmentationType;

if contains(paramAugmentation,'KdepthFx')
    params.Kdepth(1,1) = params.Kdepth(1,1) + randPixMovement/params.KdepthMatNormalizationMat(1);
end
if contains(paramAugmentation,'KdepthFy')
    params.Kdepth(2,2) = params.Kdepth(2,2) + randPixMovement/params.KdepthMatNormalizationMat(2);
end
if contains(paramAugmentation,'KrgbFx')
    params.Krgb(1,1) = params.Krgb(1,1) + randPixMovement/params.KrgbMatNormalizationMat(1,1);
end
if contains(paramAugmentation,'KrgbFy')
    params.Krgb(2,2) = params.Krgb(2,2) + randPixMovement/params.KrgbMatNormalizationMat(2,2);
end
if contains(paramAugmentation,'KrgbCx')
    params.Krgb(1,3) = params.Krgb(1,3) + randPixMovement/params.KrgbMatNormalizationMat(1,3);
end
if contains(paramAugmentation,'KrgbCy')
    params.Krgb(2,3) = params.Krgb(2,3) + randPixMovement/params.KrgbMatNormalizationMat(2,3);
end
if contains(paramAugmentation,'Ralpha')
    params.xAlpha = params.xAlpha + randPixMovement/params.RnormalizationParams(1);
end
if contains(paramAugmentation,'Rbeta')
    params.yBeta = params.yBeta + randPixMovement/params.RnormalizationParams(2);
end
if contains(paramAugmentation,'Rgamma')
    params.zGamma = params.zGamma + randPixMovement/params.RnormalizationParams(3);
end
if contains(paramAugmentation,'Tx')
    params.Trgb(1) = params.Trgb(1) + randPixMovement/params.TmatNormalizationMat(1);
end
if contains(paramAugmentation,'Ty')
    params.Trgb(2) = params.Trgb(2) + randPixMovement/params.TmatNormalizationMat(2);
end
if contains(paramAugmentation,'Tz')
    params.Trgb(3) = params.Trgb(3) + randPixMovement/params.TmatNormalizationMat(3);
end
if contains(paramAugmentation,'scaleDepthX') || contains(paramAugmentation,'scaleDepthY')...
        || contains(paramAugmentation,'offsetDepthX')|| contains(paramAugmentation,'offsetDepthY')
    [xim,yim] = meshgrid(1:params.depthRes(2),1:params.depthRes(1));
end

if contains(paramAugmentation,'scaleDepthX')
    scaleParam = randPixMovement/(params.rgbRes(2)/params.depthRes(2));
    halfRes = (1+params.depthRes(2))/2;
    xim = (xim-halfRes)*(halfRes+scaleParam)/halfRes + halfRes; % scales the image so the edge moves by scaleParam
end
if contains(paramAugmentation,'scaleDepthY')
    scaleParam = randPixMovement/(params.rgbRes(1)/params.depthRes(1));
    halfRes = (1+params.depthRes(1))/2;
    yim = (yim-halfRes)*(halfRes+scaleParam)/halfRes + halfRes; % scales the image so the edge moves by scaleParam
end
if contains(paramAugmentation,'offsetDepthX')
    offsetParam = randPixMovement/(params.rgbRes(2)/params.depthRes(2));
    xim = xim+offsetParam;
end
if contains(paramAugmentation,'offsetDepthY')
    offsetParam = randPixMovement/(params.rgbRes(1)/params.depthRes(1));
    yim = yim+offsetParam;
end

if contains(paramAugmentation,'scaleDepthX') || contains(paramAugmentation,'scaleDepthY')...
        || contains(paramAugmentation,'offsetDepthX')|| contains(paramAugmentation,'offsetDepthY')
    minX = min(xim(:)); maxX = max(xim(:));
    minY = min(yim(:)); maxY = max(yim(:));
    paddedAdd = 2*ceil(max([abs(minX),abs(minY),maxX - size(frame.z(:,:,end),2),maxY - size(frame.z(:,:,end),1)]));
    
    xim = xim + paddedAdd;
    yim = yim + paddedAdd;
    z4Interp = padarray(frame.z(:,:,end),double([paddedAdd paddedAdd]),'replicate');
    z = interp2(z4Interp,xim,yim);
    
    i4Interp =  padarray(frame.i(:,:,end),double([paddedAdd paddedAdd]),'replicate');
    ir = interp2(i4Interp,xim,yim);
    if any(isnan(z(:))) || any(isnan(ir(:)))
        error('Problem in padded image')
    end
    frame.z(:,:,end) = z;
    frame.i(:,:,end) = ir;
end

params.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha,params.yBeta,params.zGamma);
params.rgbPmat = params.Krgb*[params.Rrgb,params.Trgb];


end

