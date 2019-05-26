function [res] = computeCal(cbCorners,kDepth,params)
    numViews=size(cbCorners,1);
    CoordsObjectCameraLC = cell(1, numViews);
    CoordsCameraRgbLC = cell(1, numViews);
    CoordsCameraLeftLC = cell(1, numViews);
    countCornersLC = 0;
    
    for i=1:numViews
        corLeft = cbCorners{i,1}';
        idxsl = find(~isnan(corLeft(1,:)));
        corRGB = cbCorners{i,2}';
        idxsc = find(~isnan(corRGB(1,:)));
        idxsLC = intersect(idxsl, idxsc);
        corners3d = cbCorners{i,3}';
        CoordsObjectCameraLC{i} = corners3d(: ,idxsLC);
        CoordsCameraLeftLC{i} = corLeft(:, idxsLC);
        CoordsCameraRgbLC{i} = corRGB(:, idxsLC);
        countCornersLC = countCornersLC + length(idxsLC);
    end
    
    res.depth.k=kDepth;
    res.depth.rms=0;
    res.depth.d=[0 0 0 0 0];
    
    [res.color.rms, res.color.k, res.color.d] = ocv.CalibrateSingle(CoordsObjectCameraLC, CoordsCameraRgbLC,...
        params.RGBImageSize, params.LensModel.distortionNumRGB, params.LensModel.arePixelsSquare);
    [res.extrinsics.rms, res.extrinsics.r, res.extrinsics.t] = ...
        ocv.CalibratePair(CoordsObjectCameraLC, CoordsCameraLeftLC, CoordsCameraRgbLC,...
        double(res.depth.k), res.depth.d, res.color.k, res.color.d, params.LRImageSize, params.RGBImageSize, params.LensModel.arePixelsSquare, 1);
    
    % normalize color K
    K = res.color.k;
    for i=1:2
        K(i,i) = K(i,i)*2./params.RGBImageSize(i);
        K(i,3) = K(i,3)*2./params.RGBImageSize(i) - 1;
    end
    
    res.color.Kn = K;
    
end

