RmsData = [];
scales = [ 0.984:0.004:0.996 0.998:0.002:1.002 1.004:0.004:1.016];
isDisp = 0;
Iv2Checker = 0; 
baseDir = 'W:\testResults\05200916\init';
for i=1:length (scales)
    for j=1:length (scales)
        hscale = num2str(scales(j));
        vscale = num2str(scales(i));
        if scales(i) == 1
            vscale = '1.0';
        end
        if scales(j) == 1
            hscale = '1.0';
        end
        currDir = fullfile(baseDir,sprintf('hScale_%s_vScale_%s',hscale,vscale));
        load(fullfile(currDir,'cameraConfig.mat'));
        depthRes = [640 480];
        rgbRes = [1920 1080];
        
        %readFiles
        rgbFiles = dirFiles(currDir,'*.binrgb',1);
        rgbIm = cellfun(@(x) du.formats.readBinRGBImage(x,rgbRes,5),rgbFiles(1),'uni',0);
        
        zFiles = dirFiles(currDir,'*.binz',1);
        zIm = cellfun(@(x) double(du.formats.readBinFile(x,depthRes,16))./double(zMaxSubMM),zFiles(1),'uni',0);
        
        iFiles = dirFiles(currDir,'*.bin8',1);
        iIm = cellfun(@(x) double(du.formats.readBinFile(x,depthRes,8)),iFiles(1),'uni',0);
        
        if Iv2Checker
            [ptsI,cMap] = Calibration.aux.CBTools.findCheckerboardFullMatrix(iIm{1});
            [ptsRgb] = Calibration.aux.CBTools.findCheckerboardFullMatrix(rgbIm{1});

        else
            chckI  = CBTools.Checkerboard(iIm{1});
            ptsI = chckI.getGridPointsMat-1;
            cMap = chckI.getColorMap;
            
            chckRgb  = CBTools.Checkerboard(rgbIm{1});
            ptsRgb = chckRgb.getGridPointsMat-1;
            
     
        end
        zPts = Calibration.aux.CBTools.valuesFromWhites(zIm{1},ptsI,cMap,1/8);
        verts = NaN(size(cMap));
        verts(~isnan(cMap)) = zPts;
        ptsV = cat(3,(ptsI(:,:,1) - zK(1,3))./zK(1,1).*verts,(ptsI(:,:,2) - zK(2,3))./zK(2,2).*verts,verts);
        pointCloud = reshape(ptsV,[],3)';
        rgbKn = du.math.normalizeK(rgbK,rgbRes);
        %rgbKn = rgbK;
        
        Pt = rgbKn*[rgbRotation -1000*rgbTranslation(:)];
        
        zKn = du.math.normalizeK(zK,depthRes);
        [X,Y,Z] = du.math.unprojectImage(zIm{1},zKn,zeros(1,5));
        [U, V] = du.math.mapTexture(Pt,X,Y,Z);
        undistIm = du.math.undistortImage(double(rgbIm{1}), rgbK, rgbDistortion);
        wR = du.math.imageWarp( undistIm, V*rgbRes(2), U*rgbRes(1));
        imshowpair(iIm{1},wR);
        
        
        [U, V] = du.math.mapTexture(Pt,pointCloud(1,:)',pointCloud(2,:)',pointCloud(3,:)');
        uvmap = [rgbRes(1).*U';rgbRes(2).*V'];
        %uvmap = [U';V'];
        uvmap_d = du.math.distortCam(uvmap, rgbK, rgbDistortion);
        
        imagesc(rgbIm{1}); colormap gray;
        hold on;
        plot(ptsRgb(:,:,1),ptsRgb(:,:,2),'+r')
        plot(uvmap_d(1,:)',uvmap_d(2,:)','ob')
        hold off
        errs = reshape(ptsRgb,[],2) - uvmap_d';
        rms = sqrt(nanmean(sum(errs.^2,2)));
        quiver(uvmap_d(1,:)',uvmap_d(2,:)',errs(:,1),errs(:,2));
        title(sprintf('rms %g FHD pix',rms))
        RmsData(end+1) = rms;
    end
end

dispMat(reshape(RmsData,[length(scales) length(scales)]),scales,scales);
