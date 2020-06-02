clear
dataDir = 'X:\Data\IvCam2\OnlineCalibration\Field Tests';

%definitions
lutScales = [ 0.98:0.004:0.996 0.998:0.002:1.002 1.004:0.004:1.02];
rgbRes = [1920 1080];

%metric definitions
metricNames = {'gridInterDistance_errorRmsAF',...
    'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
    'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
uvMetricsId = [4,5];
additionalMetricsId = [6,7];
gidMeticId = 2;
friendlyNames = {'GID','ScaleX','ScaleY','UV_rms_LUT','UV_max_LUT','UV_rms','UV_max' };
mUnits = {'deg','mm','factor','factor','pix','pix','pix','pix'};
for metrixIdx=1:length(friendlyNames)
    metricViz(metrixIdx).name = friendlyNames{metrixIdx};
    metricViz(metrixIdx).units = mUnits{metrixIdx};
    metricViz(metrixIdx).pre = [];
    metricViz(metrixIdx).post = [];
end

%get all the tests and units
units = dirFolders(dataDir);
[~,~,testInfo] = xlsread(fullfile(dataDir,'fieldTestInfo.xlsx'));
infounits = unique(testInfo(2:end,2));
units = intersect(units,infounits);
units = units([1,2,3,5]);
resStruct = struct();
ridx = 1;

%run on all units and tests
for uid=1:length(units)
    unitID = units{uid};
    
    %extract lut data and checkpoints
    [data] = OnlineCalibration.robotAnalysis.processSingleLut(fullfile(dataDir,unitID,'result.csv'),metricNames);
    for metrixIdx=1:length(data.metrics)
        metricViz(metrixIdx).interpolat = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(metrixIdx).values');
    end
    lutCheckers = OnlineCalibration.robotAnalysis.findLutCheckerPoints(fullfile(dataDir,unitID,'test_swipeScaleStationary'),lutScales);
    
    
    idxs = find(strcmp(unitID,testInfo(:,2)));
    unitTests = testInfo(idxs,3);
    for tid=1:length(unitTests)
        [~,sceneName] = fileparts(unitTests{tid});
        iterations = dirFolders(unitTests{tid},'iteration*');
        for iid = 1:length(iterations)
            try
                %load test results and inputs
                mod = loadjson(fullfile(unitTests{tid},iterations{iid},[iterations{iid} '_before'],'modifications.json'));
                modCal = loadjson(fullfile(unitTests{tid},iterations{iid},[iterations{iid} '_before'],'modified_calibration.json'));
                acDir = dirFolders(fullfile(unitTests{tid},iterations{iid}),'ac*',1);
                res = loadjson(fullfile(acDir{1},'1','results_1.json'));
                inData = load(fullfile(acDir{1},'1','InputData.mat'));
                
                frame = inData.frame;
                flowParams = inData.flowParams; 
                CameraParams = inData.params;
                colorRes = size(frame.yuy2);
                depthRes = size(frame.z);
                flowParams.params.rgbRes = colorRes([2;1]);
                flowParams.params.depthRes = depthRes;

                
                flowParams.params.RnormalizationParams = cell2mat(flowParams.params.RnormalizationParams)';
                flowParams.params.KrgbMatNormalizationMat = [cell2mat(flowParams.params.KrgbMatNormalizationMat{1,1});cell2mat(flowParams.params.KrgbMatNormalizationMat{1,2});cell2mat(flowParams.params.KrgbMatNormalizationMat{1,3})];
                flowParams.params.TmatNormalizationMat = cell2mat(flowParams.params.TmatNormalizationMat)';
                flowParams.params.KdepthMatNormalizationMat = [cell2mat(flowParams.params.KdepthMatNormalizationMat{1,1});cell2mat(flowParams.params.KdepthMatNormalizationMat{1,2});cell2mat(flowParams.params.KdepthMatNormalizationMat{1,3});cell2mat(flowParams.params.KdepthMatNormalizationMat{1,4})];
                flowParams.params.maxXYMovementPerIteration = cell2mat(flowParams.params.maxXYMovementPerIteration);
                flowParams.params.rgbPmatNormalizationMat = [cell2mat(flowParams.params.rgbPmatNormalizationMat{1,1});cell2mat(flowParams.params.rgbPmatNormalizationMat{1,2});cell2mat(flowParams.params.rgbPmatNormalizationMat{1,3})];

                params = flowParams.params;

                RGBcalRes.Fx = CameraParams.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rFx;
                RGBcalRes.Fy = CameraParams.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rFy;
                RGBcalRes.Cy = CameraParams.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rPy;
                RGBcalRes.Cx = CameraParams.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rPx;

                Kl = [RGBcalRes.Fx, 0, RGBcalRes.Cx;
                      0, RGBcalRes.Fy, RGBcalRes.Cy;
                      0, 0, 1];
                params.Krgb = Kl;
                %%
                DepthcalRes.Fx = CameraParams.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rFx;
                DepthcalRes.Fy = CameraParams.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rFy;
                DepthcalRes.Cy = CameraParams.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rPy;
                DepthcalRes.Cx = CameraParams.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rPx;

                Kl = [DepthcalRes.Fx, 0, DepthcalRes.Cx;
                      0, DepthcalRes.Fy, DepthcalRes.Cy;
                      0, 0, 1];
                params.Kdepth = Kl;
                %%
                if iscell(CameraParams.Rgb.Distortion)
                    params.rgbDistort = cell2mat(CameraParams.Rgb.Distortion);
                else
                    params.rgbDistort = CameraParams.Rgb.Distortion';
                end
                params.zMaxSubMM = 1;
                if iscell(CameraParams.Rgb.Extrinsics.Depth.Translation)
                    params.Trgb = cell2mat(CameraParams.Rgb.Extrinsics.Depth.Translation)';
                else
                    params.Trgb = CameraParams.Rgb.Extrinsics.Depth.Translation;
                end
                if iscell(CameraParams.Rgb.Extrinsics.Depth.RotationMatrix)
                    params.Rrgb = reshape(cell2mat(CameraParams.Rgb.Extrinsics.Depth.RotationMatrix),[3,3])';
                else
                    params.Rrgb = reshape(CameraParams.Rgb.Extrinsics.Depth.RotationMatrix,[3,3])';
                end
                [params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);

                params.rgbPmat = params.Krgb*[ params.Rrgb, params.Trgb];

                
% 
%                 namesAll = fieldnames(params);
%                 for i = 1:numel(namesAll)
%                     if isnumeric(params.(namesAll{i}))
%                         params.(namesAll{i}) = double(params.(namesAll{i}));
%                     end
%                 end
                
                params = OnlineCalibration.aux.getParamsForAC(params);
                acInputData.binWithHeaders = 1;
                acInputData.calibDataBin  = inData.ac2_dsm_params.table_313;
                acInputData.acDataBin  = inData.ac2_dsm_params.table_240;
                acInputData.DSMRegs.dsmXscale = inData.ac2_dsm_params.extLdsmXscale;
                acInputData.DSMRegs.dsmXoffset = inData.ac2_dsm_params.extLdsmXoffset;
                acInputData.DSMRegs.dsmYscale = inData.ac2_dsm_params.extLdsmYscale;
                acInputData.DSMRegs.dsmYoffset = inData.ac2_dsm_params.extLdsmYoffset;
                [validParamsRerun,paramsRerun,~,newAcData,dbgRerun] = OnlineCalibration.aux.runSingleACIteration(frame,params,params,acInputData);
                
                hfactor = newAcData.hFactor;
                vfactor = newAcData.vFactor;
                
                %calculate uv mapping
                calMod.hfactor = dbgRerun.acDataIn.hFactor;
                calMod.vfactor = dbgRerun.acDataIn.vFactor;
                calMod.Krgb = params.Krgb;
                calMod.Rrgb = params.Rrgb;
                calMod.Trgb = params.Trgb;
                calMod.rgbRes = params.rgbRes;
                calMod.rgbDistort = params.rgbDistort;
                
                calRes.Krgb = paramsRerun.Krgb;
                calRes.Rrgb = paramsRerun.Rrgb;
                calRes.Trgb = paramsRerun.Trgb;
                calRes.rgbRes = paramsRerun.rgbRes;
                calRes.rgbDistort = paramsRerun.rgbDistort;
                calRes.hfactor = newAcData.hFactor;
                calRes.vfactor = newAcData.vFactor;
                
                uvErrorsMod = OnlineCalibration.robotAnalysis.calcUvMapError(...
                    lutCheckers,calMod.hfactor,calMod.vfactor,calMod);
                uvErrorsRes = OnlineCalibration.robotAnalysis.calcUvMapError(...
                    lutCheckers,calRes.hfactor,calRes.vfactor,calRes);
                
                %create test statistic line
                resStruct(ridx).Unit = unitID;
                resStruct(ridx).Scene = sceneName;
                resStruct(ridx).Iteration = iterations{iid};
                resStruct(ridx).ModHfactor = calMod.hfactor;
                resStruct(ridx).ModVfactor = calMod.vfactor;
                resStruct(ridx).ModRGB = 'NA';
                resStruct(ridx).IsConverge = validParamsRerun;
                resStruct(ridx).ResHfactor = hfactor;
                resStruct(ridx).ResVfactor = vfactor;
                for metrixIdx=1:length(data.metrics)
                    preV = metricViz(metrixIdx).interpolat(mod.ac_depth.h_factor,mod.ac_depth.v_factor);
                    postV = metricViz(metrixIdx).interpolat(hfactor,vfactor);
                    resStruct(ridx).([metricViz(metrixIdx).name '_before']) = preV;
                    resStruct(ridx).([metricViz(metrixIdx).name '_after']) = postV;
                    metricViz(metrixIdx).pre(end+1) = preV;
                    metricViz(metrixIdx).post(end+1) = postV;
                end
                for metrixIdx=1:length(additionalMetricsId)
                    metricViz(additionalMetricsId(metrixIdx)).pre(end+1) = uvErrorsMod(metrixIdx);
                    metricViz(additionalMetricsId(metrixIdx)).post(end+1) = uvErrorsRes(metrixIdx);
                    resStruct(ridx).([metricViz(additionalMetricsId(metrixIdx)).name '_before']) = uvErrorsMod(metrixIdx);
                    resStruct(ridx).([metricViz(additionalMetricsId(metrixIdx)).name '_after']) = uvErrorsRes(metrixIdx);
                end
                fprintf('[%d] [%d] GID Pre/Post: [%2.2g/%2.2g]\n',ridx,resStruct(ridx).IsConverge,resStruct(ridx).GID_before,resStruct(ridx).GID_after);
                ridx = ridx+1;

            catch ex
            end
            
        end
    end
    
end

%plot results
labelsGT = [resStruct(:).IsConverge];
labelsActual = [resStruct(:).IsConverge];
OnlineCalibration.robotAnalysis.plotResultMetrics(labelsGT,labelsActual,metricViz);

save 'env.mat';
%{
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
[data] = OnlineCalibration.robotAnalysis.processSingleLut(lutFile,[]);


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
metricViz = struct('name',[],'pre',[],'post',[],'units',[]);

for metrixIdx=1:length(data.metrics)
    intrp = griddedInterpolant(data.hfactor',data.vfactor',data.metrics(metrixIdx).values');
    metricViz(metrixIdx).name = friendlyNames{metrixIdx};
    metricViz(metrixIdx).pre = repmat(intrp(hscaleMod,vscaleMod),size(hfactors));
    metricViz(metrixIdx).post = intrp(hfactors,vfactors);
    metricViz(metrixIdx).units = mUnits{metrixIdx};
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
            
            
            rgbKn = du.math.normalizeK(Krgb, rgbRes);
            %rgbKn = rgbK;
            
            Pt = rgbKn*[Rrgb Trgb];
            [U, V] = du.math.mapTexture(Pt,pointCloud(1,:)',pointCloud(2,:)',pointCloud(3,:)');
            uvmap = [rgbRes(1).*U';rgbRes(2).*V'];
            %uvmap = [U';V'];
            uvmap_d = du.math.distortCam(uvmap, Krgb, rgbDistort);
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
        metricViz(metrixIdx+1).name = extraMetricsNames{j};
        metricViz(metrixIdx+1).pre = repmat(intrp(hscaleMod,vscaleMod),size(hfactors));
        metricViz(metrixIdx+1).post = uv_erros(:,j);
        metricViz(metrixIdx+1).units = 'pix';
        
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
        labelsGT = (abs(metricViz(2).post) < gidTh )& (abs(metricViz(5).post ) < uvMappTh);
    otherwise
        labelsGT = true(size(labelsActual));
end
OnlineCalibration.robotAnalysis.plotResultMetrics(labelsGT,labelsActual,metricViz,'singlePre');

tabplot();
boxplot( hvfacors(~labelsActual,:));
xticklabels({'H factor','V factor'});
title('statstics of H\V factors');


%}