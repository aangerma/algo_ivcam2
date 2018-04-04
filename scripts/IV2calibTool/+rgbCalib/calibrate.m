function calibrate(outputFolder)
    if(outputFolder(end)~=filesep)
        outputFolder(end+1)=filesep;
    end
    intermidiateFldr=fullfile(outputFolder,'algoInternal');
    
    mkdirSafe(outputFolder);
    mkdirSafe(intermidiateFldr);
    [imgs,k_depth]=rgbCalib.grabImages();
    save(fullfile(intermidiateFldr,'imgs.mat'),imgs);
    
    targetParams = Calibration.getTargetParams();
    tbsz=[targetParams.cornersX targetParams.cornersY];
    cbCorners=cell();
    for i=1:size(imgs,1)
        crnrns=cell(1,2);
        bsz=cell(1,2);
        for j=1:2
            imgn = normByMax(imgs{i,j});
            [crnrns{j},bsz{j}]=detectCheckerboardPoints(imgn);
        end
     
        if(isequal(bsz{1}-1,tbsz) && isequal(bsz{1}-1,tbsz))
            cbCorners(end+1,:)=crnrns;%#ok
        end
    end
    
    res=runCalibration(cbCorners,targetParams,k_depth);
    struct2xmlWrapper(res,fullfile(outputFolder,'rgbCalib.xml'));
    
end

function res = runCalibration(cbCorners,targetInfo,k_depth)
    % OCV version of the calibration    


    corners3d = rgbCalib.create3DCorners(targetInfo);
    
    CoordsObjectCameraLC = cell(1, numViews);
    CoordsCameraRgbLC = cell(1, numViews);
    CoordsCameraLeftLC = cell(1, numViews);
    countCornersLC = 0;
    
    for i=1:size(cbCorners,1)
        corLeft = cbCorners{i,1};
        idxsl = find(~isnan(corLeft(1,:)));
        corRGB = cbCorners{i,2};
        idxsc = find(~isnan(corRGB(1,:)));
        idxsLC = intersect(idxsl, idxsc);
        CoordsObjectCameraLC{i} = corners3d(: ,idxsLC);
        CoordsCameraLeftLC{i} = corLeft(:, idxsLC);
        CoordsCameraRgbLC{i} = corRGB(:, idxsLC);
        countCornersLC = countCornersLC + length(idxsLC);
    end
    
        if(isempty(k_depth))
        [res.depth.rms, res.depth.k, res.depth.d] = Calibration.rgbCalib.DSOcvCalibrateSingle(CoordsObjectCameraLC, CoordsCameraLeftLC, params.LRImageSize, params.LensModel.distortionNumLR, params.LensModel.arePixelsSquare);
        else
            res.depth.k=k_depth;
            res.depth.rms=0;
            res.depth.d=[0 0 0 0 0];
        end
        [res.color.rms, res.color.k, res.color.d] = Calibration.rgbCalib.DSOcvCalibrateSingle(CoordsObjectCameraLC, CoordsCameraRgbLC, params.RGBImageSize, params.LensModel.distortionNumRGB, params.LensModel.arePixelsSquare);
        [res.extrinsics.rms, res.extrinsics.r, res.extrinsics.t] = Calibration.RgbCalib.DSOcvCalibratePair(CoordsObjectCameraLC, CoordsCameraLeftLC, CoordsCameraRgbLC, Kl, dl, Kc, dc, params.LRImageSize, params.RGBImageSize, params.LensModel.arePixelsSquare, 1);

end
