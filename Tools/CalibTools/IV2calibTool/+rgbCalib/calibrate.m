function calibrate(params,fprintff)
    calibparams.rgbExtrinsicsRMSthreshold = 3.0;
    
    outputFolder=params.outputFolder;
    if(isempty(outputFolder) || outputFolder(end)~=filesep)
        outputFolder(end+1)=filesep;
    end
    
    intermidiateFldr=fullfile(outputFolder,'algoInternal',filesep);
    mkdirSafe(outputFolder);
    mkdirSafe(intermidiateFldr);
    fprintff('[*] grabbing images...');
    [imgs,k_depth]=rgbCalib.grabImages();
    fprintff('done\n');
    save(fullfile(intermidiateFldr,'imgs.mat'),'imgs','k_depth');
    fprintff('[*] finding corneres');
    
    targetParams = Calibration.getTargetParams();
    tbsz=[targetParams.cornersY targetParams.cornersX];
    cbCorners=cell(0,2);
    for i=1:size(imgs,1)
        
        crnrns=cell(1,2);
        bsz=cell(1,2);
        for j=1:2
            imgn = normByMax(mean(imgs{i,j},3));
            [crnrns{j},bsz{j}]=detectCheckerboardPoints(imgn);
        end
     
        if(isequal(bsz{1}-1,tbsz) && isequal(bsz{1}-1,tbsz))
            cbCorners(end+1,:)=crnrns;%#ok
            fprintff('.');
        else
            fprintff('x');
        end
        
    end
    fprintff(' done (found corners in %d out of %d)\n',size(cbCorners,1),size(imgs,1));
    fprintff('[*] calibrating...',size(cbCorners,1),size(imgs,1));
    res=runCalibration(cbCorners,targetParams,k_depth,params.distortion);
    fprintff('done (%d)\n',res.extrinsics.rms);
    xmlfn=fullfile(outputFolder,'rgbCalib.xml');
    struct2xmlWrapper(res,xmlfn);
    
    fprintff('[*] copying to device...');
    caminf = ADB;
    caminf.shell('mkdir /sdcard/rgbcalib');
    [v,failed]=caminf.cmd('push %s /sdcard/rgbcalib/rgbCalibResults.xml',xmlfn);
    if(failed)
        fprintff('Failed(%s)',v);
    else
        fprintff('copied to /sdcard/rgbcalib/rgbCalibResults.xml\n');
    end
    
    fprintff('[*] calibration ended - ');
    if(res.extrinsics.rms>calibparams.rgbExtrinsicsRMSthreshold)
        fprintff('fail');
    else
        fprintff('pass');
    end
end

function res = runCalibration(cbCorners,targetInfo,k_depth,rgbDistoration)
    % OCV version of the calibration    
    numViews=size(cbCorners,1);
    params.RGBImageSize = [4032 3024];
    params.LRImageSize = [640 480];
    params.LensModel.distortionNumRGB = 5*rgbDistoration;
    params.LensModel.distortionNumLR = 0;
    params.LensModel.arePixelsSquare = false;
    
    [gy,gx]=ndgrid((0:targetInfo.cornersY-1)*targetInfo.mmPerUnitY,(0:targetInfo.cornersX-1)*targetInfo.mmPerUnitX);
    
    corners3d = [gx(:) gy(:) zeros(numel(gy),1)]';
    
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
        CoordsObjectCameraLC{i} = corners3d(: ,idxsLC);
        CoordsCameraLeftLC{i} = corLeft(:, idxsLC);
        CoordsCameraRgbLC{i} = corRGB(:, idxsLC);
        countCornersLC = countCornersLC + length(idxsLC);
    end
    
        if(isempty(k_depth))
        [res.depth.rms, res.depth.k, res.depth.d] = rgbCalib.DSOcvCalibrateSingle(CoordsObjectCameraLC, CoordsCameraLeftLC, params.LRImageSize, params.LensModel.distortionNumLR, params.LensModel.arePixelsSquare);
        else
            res.depth.k=k_depth;
            res.depth.rms=0;
            res.depth.d=[0 0 0 0 0];
        end
        [res.color.rms, res.color.k, res.color.d] = rgbCalib.DSOcvCalibrateSingle(CoordsObjectCameraLC, CoordsCameraRgbLC, params.RGBImageSize, params.LensModel.distortionNumRGB, params.LensModel.arePixelsSquare);
        [res.extrinsics.rms, res.extrinsics.r, res.extrinsics.t] = rgbCalib.DSOcvCalibratePair(CoordsObjectCameraLC, CoordsCameraLeftLC, CoordsCameraRgbLC, res.depth.k, res.depth.d, res.color.k, res.color.d, params.LRImageSize, params.RGBImageSize, params.LensModel.arePixelsSquare, 1);

end
