function [] = displayRobotTestResults(acResultsFile,lutFile, hscaleMod,vscaleMod, acDataPath, lutDataPath)
    
    %usage example
    %{
    baseDir = 'W:\testResults\05201048\';
    hscaleMod =  0.995; vscaleMod = 1.005 ;
    
    acResultsFile = fullfile(baseDir,'results.csv');
    lutFile = fullfile(baseDir,'lutTable.csv');
    acDataPath = fullfile(baseDir,sprintf('hScale_%g_vScale_%g',hscaleMod,vscaleMod));
    lutDataPath = fullfile(baseDir,'init');
    OnlineCalibration.robotAnalysis.displayRobotTestResults(acResultsFile,lutFile, hscaleMod,vscaleMod,acDataPath, lutDataPath)
    %}
    
    gtLabelMode = 0; %0 - gt==algo res, 2\3 - distance from lut minima (gid\uv mapping),3 - according to lut results
    gtTh = 0.004;
    uvMappTh = Inf;
    gidTh  = 0.8;
    
    
    metricNames = {'LDD_Temperature','gridInterDistance_errorRmsAF',...
        'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
        'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
    uvMetricsId = [5,6];
    gidMeticId = 2;
    friendlyNames = {'Temp','GID','ScaleX','ScaleY','LUT UV RMS','LUT UV max'};
    mUnits = {'deg','mm','factor','factor','pix','pix'};
    [data] = OnlineCalibration.robotAnalysis.processSingleLut(lutFile,metricNames);
    
    [num,txt] = xlsread(acResultsFile);
    resultIdx = find( strcmp(txt(1,:),'status'));
    hFactorIdx = find( strcmp(txt(1,:),'hFactor'));
    vFactorIdx = find( strcmp(txt(1,:),'vFactor'));
    hDistIdx = find( strcmp(txt(1,:),'hDistortion'));
    vDistIdx = find( strcmp(txt(1,:),'vDistortion'));
    iterIdx = find( strcmp(txt(1,:),'iteration'));
    
    
    
    modIdxs = find((num(:,hDistIdx) == hscaleMod) & (num(:,vDistIdx) == vscaleMod));
    labelsActual = logical(num(modIdxs,resultIdx));
    
    %get actual UV mapping errors
    if exist('lutDataPath', 'var') && exist(lutDataPath, 'dir')
        lutCheckers = OnlineCalibration.robotAnalysis.findLutCheckerPoints(lutDataPath);
    end  
    
    hfactors = num(modIdxs,hFactorIdx);
    vfactors = num(modIdxs,vFactorIdx);
    hvfacors = [hfactors vfactors];

    %[~,preIdx] = min(vec(([data(:).hfactor]-hscaleMod).^2 + ([data(:).vfactor]-vscaleMod).^2));
    metricVisualization = struct('name',[],'pre',[],'post',[],'units',[]);
    
    for metrixIdx=1:length(data.metrics)
        intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(metrixIdx).values');
        metricVisualization(metrixIdx).name = friendlyNames{metrixIdx};
        metricVisualization(metrixIdx).pre = repmat(intrp(hscaleMod,vscaleMod),size(hfactors));
        metricVisualization(metrixIdx).post = intrp(hfactors,vfactors);
        metricVisualization(metrixIdx).units = mUnits{metrixIdx};
        %{
        tabplot(metrixIdx+1,fig)
        histogram(metricVisualization(metrixIdx).post(labelsActual),round(N/10),'Normalization','probability');
        vline(data.metrics(metrixIdx).values(preIdx),'r-','Pre');
        title(sprintf('SN: %s %s',data.sn{1}(end-7:end), friendlyNames{metrixIdx}))
        ylabel('probability');
        xlabel(mUnits{metrixIdx});
        %saveas(fig,fullfile(outDname,sprintf('%s_%s.png',data.sn{1}(end-7:end),metricNames{i})));
        %}
    end
    
    if exist('acDataPath', 'var') && exist(acDataPath, 'dir')
        for i=1:length(modIdxs)
            acData = load(fullfile(acDataPath,sprintf('%d_data.mat',num(modIdxs(i),iterIdx))));
            [minval,idx] = min(([lutCheckers(:).hScale]-num(modIdxs(i),hFactorIdx)).^2 +...
                ([lutCheckers.vScale]-num(modIdxs(i),vFactorIdx)).^2);
            if minval <0.05
                ptsI = lutCheckers(idx).irPts;
                pointCloud = lutCheckers(idx).zPts;
                ptsRgb = lutCheckers(idx).rgbPts;
                
                
                rgbKn = du.math.normalizeK( acData.newParams.Krgb, acData.newParams.rgbRes);
                %rgbKn = rgbK;
                
                Pt = rgbKn*[acData.newParams.Rrgb acData.newParams.Trgb];
                [U, V] = du.math.mapTexture(Pt,pointCloud(1,:)',pointCloud(2,:)',pointCloud(3,:)');
                uvmap = [acData.newParams.rgbRes(1).*U';acData.newParams.rgbRes(2).*V'];
                %uvmap = [U';V'];
                uvmap_d = du.math.distortCam(uvmap, acData.newParams.Krgb, acData.newParams.rgbDistort);
                %{
                imagesc(rgbIm{1}); colormap gray;
                hold on;
                plot(ptsRgb(:,:,1),ptsRgb(:,:,2),'+r')
                plot(uvmap_d(1,:)',uvmap_d(2,:)','ob')
                hold off
                %}
                errs = reshape(ptsRgb,[],2) - uvmap_d';
                uv_erros(i,:) = [sqrt(nanmean(sum(errs.^2,2)))  prctile(sqrt(sum(errs.^2,2)),95) prctile(errs,50)] ;
            else
                uv_erros(i,:) = NaN(1,4);
                
            end
            
        end
        extraMetricsNames = {'Sampled UV Rms','Sampled UV max'};
        for j=1:length(uvMetricsId)
            intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(uvMetricsId(j)).values');
            metricVisualization(metrixIdx+1).name = extraMetricsNames{j};
            metricVisualization(metrixIdx+1).pre = repmat(intrp(hscaleMod,vscaleMod),size(hfactors));
            metricVisualization(metrixIdx+1).post = uv_erros(:,j);
            metricVisualization(metrixIdx+1).units = 'pix';
            
        end
    end
    
    switch gtLabelMode
        case 0
            labelsGT = labelsActual;
        case {1,2}
            if gtLabelMode == 1
                [~,minId] = min(data.metrics(gidMeticId).values(:));
            else
                [~,minId] = min(data.metrics(uvMetricsId(1)).values(:));
            end
            minHfactor = data.hfactor(minId);
            minVfactor = data.vfactor(minId);
            labelsGT = (hfactors - minHfactor).^2 + (vfactors - minVfactor).^2 < gt_th.^2;
        case 3
            labelsGT = (abs(metricVisualization(2).post) < gidTh )& (abs(metricVisualization(5).post ) < uvMappTh);
        otherwise
            labelsGT = true(size(labelsActual));
    end
    OnlineCalibration.robotAnalysis.plotResultMetrics(labelsGT,labelsActual,metricVisualization,'singlePre');
    
    tabplot();
    boxplot( hvfacors(~labelsActual,:));
    xticklabels({'H factor','V factor'});
    title('statstics of H\V factors');
end