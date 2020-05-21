function lutCheckers = readLutCheckerPoints(baseDir)
    scales = [ 0.984:0.004:0.996 0.998:0.002:1.002 1.004:0.004:1.016];
    Iv2Checker = 0;
    lutCheckers = struct('hScale',[],'vScale',[],'irPts',[],'zPts',[],'rgbPts',[]);
    lidx = 1;
    for i=1:length (scales)
        for j=1:length (scales)
            lutCheckers(lidx).hScale = scales(j);
            lutCheckers(lidx).vScale = scales(i);
            
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
            
            lutCheckers(lidx).irPts = ptsI;
            lutCheckers(lidx).zPts = pointCloud;
            lutCheckers(lidx).rgbPts = ptsRgb;
            lidx = lidx+1;
        end
    end
    
end