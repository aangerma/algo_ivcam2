function [frame,params] = augmentFrameAndParams(frame,params,chooseOne)
%AUGMENTFRAMEANDPARAMS 
% This function randomly choose and insert an error to the scene/parameters

if ~isfield(params,'augmentRand01Number')
    params.augmentRand01Number = rand(1);
end
oneParamAugmentationOption = {'KdepthFx';...
                                  'KdepthFy';...
                                  'KrgbFx';...
                                  'KrgbFy';...
                                  'KrgbCx';...
                                  'KrgbCy';...
                                  'Ralpha';...
                                  'Rbeta';...
                                  'Rgamma';...
                                  'Tx';...
                                  'Ty';...
                                  'Tz';...
                                  'scaleDepthX';...
                                  'scaleDepthY';...
                                  'offsetDepthX';...
                                  'offsetDepthY';...
                                  'scaleDsmX';...
                                  'scaleDsmY';...
                                    };
nOptions = numel(oneParamAugmentationOption);
if chooseOne
    if ~isfield(params,'augmentationType')
        chosenOption = randi(nOptions);
    else
        chosenOption = find(strcmp(params.augmentationType,oneParamAugmentationOption));
    end
    augmentationMaxMovement = params.augmentationMaxMovement;
	randPixMovement = 2*augmentationMaxMovement*params.augmentRand01Number - augmentationMaxMovement;
    
    params.augmentationType = oneParamAugmentationOption{chosenOption};
    params.randPixMovement = randPixMovement;
    
    switch oneParamAugmentationOption{chosenOption}
        case 'KdepthFx'
            params.Kdepth(1,1) = params.Kdepth(1,1) + randPixMovement/params.KdepthMatNormalizationMat(1);
        case 'KdepthFy'
			params.Kdepth(2,2) = params.Kdepth(2,2) + randPixMovement/params.KdepthMatNormalizationMat(2);
        case 'KrgbFx'
			params.Krgb(1,1) = params.Krgb(1,1) + randPixMovement/params.KrgbMatNormalizationMat(1,1);
        case 'KrgbFy'
            params.Krgb(2,2) = params.Krgb(2,2) + randPixMovement/params.KrgbMatNormalizationMat(2,2);
        case 'KrgbCx'
            params.Krgb(1,3) = params.Krgb(1,3) + randPixMovement/params.KrgbMatNormalizationMat(1,3);
        case 'KrgbCy'
            params.Krgb(2,3) = params.Krgb(2,3) + randPixMovement/params.KrgbMatNormalizationMat(2,3);
        case 'Ralpha'
            params.xAlpha = params.xAlpha + randPixMovement/params.RnormalizationParams(1);
        case 'Rbeta'
            params.yBeta = params.yBeta + randPixMovement/params.RnormalizationParams(2);
        case 'Rgamma'
            params.zGamma = params.zGamma + randPixMovement/params.RnormalizationParams(3);
        case 'Tx'
            params.Trgb(1) = params.Trgb(1) + randPixMovement/params.TmatNormalizationMat(1);
        case 'Ty'
            params.Trgb(2) = params.Trgb(2) + randPixMovement/params.TmatNormalizationMat(2);
        case 'Tz'
            params.Trgb(3) = params.Trgb(3) + randPixMovement/params.TmatNormalizationMat(3);
        case 'scaleDepthX'
            [xim,yim] = meshgrid(1:params.depthRes(2),1:params.depthRes(1));
            scaleParam = randPixMovement/(params.rgbRes(2)/params.depthRes(2));
            halfRes = (1+params.depthRes(2))/2;
            xim = (xim-halfRes)*(halfRes+scaleParam)/halfRes + halfRes; % scales the image so the edge moves by max pixels
            minX = min(xim(:)); maxX = max(xim(:));
            paddedAdd = 2*ceil(max([abs(minX),maxX - size(frame.z(:,:,end),2)]));
            xim = xim + paddedAdd;
            z4Interp = padarray(frame.z(:,:,end),double([0 paddedAdd]),'replicate');
            z = interp2(z4Interp,xim,yim);
            i4Interp =  padarray(frame.i(:,:,end),double([0 paddedAdd]),'replicate');
            ir = interp2(i4Interp,xim,yim);
            if any(isnan(z(:))) || any(isnan(ir(:)))
                error('Problem in padded image')
            end
            frame.z(:,:,end) = z;
            frame.i(:,:,end) = ir;
        case 'scaleDepthY'
            [xim,yim] = meshgrid(1:params.depthRes(2),1:params.depthRes(1));
            scaleParam = randPixMovement/(params.rgbRes(1)/params.depthRes(1));
            halfRes = (1+params.depthRes(1))/2;
            yim = (yim-halfRes)*(halfRes+scaleParam)/halfRes + halfRes; % scales the image so the edge moves by max pixels
            minY = min(yim(:)); maxY = max(yim(:));
            paddedAdd = 2*ceil(max([abs(minY),maxY - size(frame.z(:,:,end),1)]));
            yim = yim + paddedAdd;
            z4Interp = padarray(frame.z(:,:,end),double([paddedAdd 0]),'replicate');
            z = interp2(z4Interp,xim,yim);
            i4Interp =  padarray(frame.i(:,:,end),double([paddedAdd 0]),'replicate');
            ir = interp2(i4Interp,xim,yim);
            if any(isnan(z(:))) || any(isnan(ir(:)))
                error('Problem in padded image')
            end
            frame.z(:,:,end) = z;
            frame.i(:,:,end) = ir;
        case 'offsetDepthX'
            [xim,yim] = meshgrid(1:params.depthRes(2),1:params.depthRes(1));
            augmentationMaxMovement = augmentationMaxMovement/(params.rgbRes(2)/params.depthRes(2));
            xim = xim+augmentationMaxMovement; 
            
            
            
             minX = min(xim(:)); maxX = max(xim(:));
            paddedAdd = 2*ceil(max([abs(minX),maxX - size(frame.z(:,:,end),2)]));
            xim = xim + paddedAdd;
            z4Interp = padarray(frame.z(:,:,end),double([0 paddedAdd]),'replicate');
            z = interp2(z4Interp,xim,yim);
            i4Interp =  padarray(frame.i(:,:,end),double([0 paddedAdd]),'replicate');
            ir = interp2(i4Interp,xim,yim);
            if any(isnan(z(:))) || any(isnan(ir(:)))
                error('Problem in padded image')
            end
            frame.z(:,:,end) = z;
            frame.i(:,:,end) = ir;
        case 'offsetDepthY'
            [xim,yim] = meshgrid(1:params.depthRes(2),1:params.depthRes(1));
            augmentationMaxMovement = augmentationMaxMovement/(params.rgbRes(1)/params.depthRes(1));
            yim = yim+augmentationMaxMovement; 
            
            minY = min(yim(:)); maxY = max(yim(:));
            paddedAdd = 2*ceil(max([abs(minY),maxY - size(frame.z(:,:,end),1)]));
            yim = yim + paddedAdd;
            z4Interp = padarray(frame.z(:,:,end),double([paddedAdd 0]),'replicate');
            z = interp2(z4Interp,xim,yim);
            i4Interp =  padarray(frame.i(:,:,end),double([paddedAdd 0]),'replicate');
            ir = interp2(i4Interp,xim,yim);
            if any(isnan(z(:))) || any(isnan(ir(:)))
                error('Problem in padded image')
            end
            frame.z(:,:,end) = z;
            frame.i(:,:,end) = ir;
        case 'scaleDsmX'
            scaleX = params.randPixMovement/params.depthRes(2);
            scaleY = 0;
            warper = OnlineCalibration.Aug.fetchDsmWarper(params.serial,depthRes,scaleX,scaleY);
        otherwise
            error('Unknown augmentation type chosen - %s',oneParamAugmentationOption{chosenOption});
    end
else
    augmentationMaxMovement = params.augmentationMaxMovement;
	randPixMovement = augmentationMaxMovement*params.augmentRand01Number;
    
    nParamsToAugment = nOptions-4; % Not including scale and offset in the image plane
    unitVec = rand(nParamsToAugment,1)-0.5;
    unitVec = unitVec./norm(unitVec);
    normalizationVec = [params.KdepthMatNormalizationMat(1:2);params.KrgbMatNormalizationMat([1;5;7;8]);params.RnormalizationParams;params.TmatNormalizationMat];
    diffVec = unitVec./normalizationVec*randPixMovement;
    
    
    params.Kdepth(1,1) = params.Kdepth(1,1) + diffVec(1);
    params.Kdepth(2,2) = params.Kdepth(2,2) + diffVec(2);
    params.Krgb(1,1) = params.Krgb(1,1) + diffVec(3);
    params.Krgb(2,2) = params.Krgb(2,2) + diffVec(4);
    params.Krgb(1,3) = params.Krgb(1,3) + diffVec(5);
    params.Krgb(2,3) = params.Krgb(2,3) + diffVec(6);
    params.xAlpha = params.xAlpha + diffVec(7);
    params.yBeta = params.yBeta + diffVec(8);
    params.zGamma = params.zGamma + diffVec(9);
    params.Trgb(1) = params.Trgb(1) + diffVec(10);
    params.Trgb(2) = params.Trgb(2) + diffVec(11);
    params.Trgb(3) = params.Trgb(3) + diffVec(12);

    
    params.augmentationType = 'joined';
    params.randPixMovement = randPixMovement;
end
params.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha,params.yBeta,params.zGamma);
params.rgbPmat = params.Krgb*[params.Rrgb,params.Trgb];


end

