function [frame,params] = augmentFrameAndParams(frame,params,method)
%AUGMENTFRAMEANDPARAMS 
% This function randomly choose and insert an error to the scene/parameters
if ~exist('method','var')
    method = 'chooseOne';
end
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
nParamsToAugment = nOptions-4; % Not including scale and offset in the image plane
if ~isfield(params,'randUnitVecForAug')
   params.randUnitVecForAug = rand(nParamsToAugment,1);
end

if strcmp(method,'chooseOne')
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
            scaleX = params.randPixMovement/params.depthRes(2)*100;
            scaleY = 0;
            warper = OnlineCalibration.Aug.fetchDsmWarper(params.serial,params.depthRes,scaleX,scaleY);
            frame = warper.ApplyWarp(frame,1);
        case 'scaleDsmY'
            scaleX = 0;
            scaleY = params.randPixMovement/params.depthRes(1)*100;
            warper = OnlineCalibration.Aug.fetchDsmWarper(params.serial,params.depthRes,scaleX,scaleY);
            frame = warper.ApplyWarp(frame,1);
        otherwise
            error('Unknown augmentation type chosen - %s',oneParamAugmentationOption{chosenOption});
    end
elseif strcmp(method,'chooseAll')
    augmentationMaxMovement = params.augmentationMaxMovement;
	randPixMovement = augmentationMaxMovement*params.augmentRand01Number;
    
    
    unitVec = params.randUnitVecForAug(1:nParamsToAugment)-0.5;
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
elseif strcmp(method,'dsmAndRotation')
    assert(isfield(params,'serial'),'Unknown unit serial for DSM augmentation');
    assert(isfield(params,'randVecForDsmAndRotation'),'randVecForDsmAndRotation should be generated so it will affect both scene and CB');
%     params.dsmScaleX = params.randVecForDsmAndRotation(1)*4-2;
%     params.dsmScaleY = params.randVecForDsmAndRotation(2)*4-2;
    rotationDiff = (vec(params.randVecForDsmAndRotation(3:5))-0.5);
    rotationDiff = rotationDiff./norm(rotationDiff);
    rotationDiff = rotationDiff./params.RnormalizationParams*params.augmentationMaxMovement*params.augmentRand01Number;
    params.xAlpha = params.xAlpha + rotationDiff(1);
    params.yBeta = params.yBeta + rotationDiff(2);
    params.zGamma = params.zGamma + rotationDiff(3);
%     [warper,dsmScaleX,dsmScaleY] = OnlineCalibration.Aug.fetchDsmWarper(params.serial,params.depthRes,params.dsmScaleX,params.dsmScaleY);
%     params.dsmScaleX = str2num(dsmScaleX);
%     params.dsmScaleY = str2num(dsmScaleY);
%     frame = warper.ApplyWarp(frame,1);
end
params.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha,params.yBeta,params.zGamma);
params.rgbPmat = params.Krgb*[params.Rrgb,params.Trgb];


end

