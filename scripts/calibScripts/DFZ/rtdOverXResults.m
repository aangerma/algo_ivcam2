function [ results,sDelay ] = rtdOverXResults( calpath ,OutputDir,rtdScale)
load(fullfile(calpath,'DFZ_Calib_Calc_in.mat'));
load(fullfile(calpath,'DFZ_im.mat'));

calibPassed = 0;
captures = {calibParams.dfz.captures.capture(:).type};
shortRangeImages = strcmp('shortRange',captures);
trainImages = strcmp('train',captures);
testImages = strcmp('test',captures);
runParams.outputFolder = OutputDir;

captures = {calibParams.dfz.captures.capture(:).type};

width = regs.GNRL.imgHsize;
hight = regs.GNRL.imgVsize;
%% find effective image "bounding box"
% read IR images
IR_image = im(1).i;
% find effective image "bounding box"
bwIm = IR_image>0;
bbox = [];
bbox([1,3]) = minmax(find(bwIm(round(size(bwIm,1)/2),:)>0.9));
lcoords = minmax(find(bwIm(:,bbox(1)+10)>0.9)');
mcoords = minmax(find(bwIm(:,round(size(bwIm,2)/2))>0.9)');
rcoords = minmax(find(bwIm(:,bbox(3)-10)>0.9)');
bbox(2) = max([lcoords(1),mcoords(1),rcoords(1)]);
bbox(4) = min([lcoords(2),mcoords(2),rcoords(2)])-bbox(2);
%%
%%  prepare d struct per scene
% read frames from dir
% average image
nof_secne = numel(captures);

croppedBoxes = zeros(size(calibParams.dfz.cropRatios,1),4);
for cropR = 1:size(calibParams.dfz.cropRatios,1)
    cropRatioX = calibParams.dfz.cropRatios(cropR,1);
    cropRatioY = calibParams.dfz.cropRatios(cropR,2);
    
    croppedBbox = bbox;
    croppedBbox(1) = croppedBbox(1) + cropRatioX*croppedBbox(3);
    croppedBbox(3) = (1-2*cropRatioX)*croppedBbox(3);
    croppedBbox(2) = croppedBbox(2) + cropRatioY*croppedBbox(4);
    croppedBbox(4) = (1-2*cropRatioY)*croppedBbox(4);
    
    croppedBoxes(cropR,:) = croppedBbox;
end
%croppedBbox = int32(croppedBbox);

for i = 1:nof_secne
    targetInfo = targetInfoGenerator('Iv2A1');
    
    d(i).i = im(i).i;
    d(i).z = im(i).z;
    
    try
        [pts,colors] = CBTools.findCheckerboardFullMatrix(d(i).i, 1,0,0.2, 1);
    catch
        [pts,colors] = CBTools.findCheckerboardFullMatrix(d(i).i, 1);
    end
    if all(isnan(pts(:)))
        error('Error! Checkerboard detection failed on image %d!',i);
    end
    grid = [size(pts,1),size(pts,2),1];
    %       [pts,grid] = Validation.aux.findCheckerboard(im(i).i,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    %        grid(end+1) = 1;
    targetInfo.cornersX = grid(1);
    targetInfo.cornersY = grid(2);
    
    
    %        d(i).c = im(i).c;
    [d(i).rpt,pts,colors] = Calibration.aux.samplePointsRtd(im(i).z,pts,regs,0,colors,calibParams.dfz.sampleRTDFromWhiteCheckers);
    
    d(i).pts = pts;
    d(i).grid = grid;
    d(i).pts3d = create3DCorners(targetInfo)';
    
    outOfBoxIdxs = ones(size(pts(:,:,1)));
    for cropR = 1:size(croppedBoxes,1)
        outOfCurrBoxIdxs = pts(:,:,1)< croppedBoxes(cropR,1) | pts(:,:,1)>(croppedBoxes(cropR,1)+croppedBoxes(cropR,3)) | ...
            pts(:,:,2)<croppedBoxes(cropR,2) | pts(:,:,2)>(croppedBoxes(cropR,2)+croppedBoxes(cropR,4));
        outOfBoxIdxs = outOfBoxIdxs & outOfCurrBoxIdxs;
    end
    
    ptsCropped1 = d(i).pts(:,:,1);
    ptsCropped2 = d(i).pts(:,:,2);
    ptsCropped1(outOfBoxIdxs)= NaN;
    ptsCropped2(outOfBoxIdxs)= NaN;
    ptsCropped = cat(3,ptsCropped1,ptsCropped2);
    colorsCropped = colors;
    colorsCropped(outOfBoxIdxs)= NaN;
    rptCropped = d(i).rpt;
    rptCropped(outOfBoxIdxs(:),:) = NaN;
    
    
    d(i).ptsCropped = ptsCropped;
    d(i).colorsCropped = colorsCropped;
    d(i).gridCropped = d(i).grid;
    d(i).rptCropped = rptCropped;
    %{
            figure,imagesc(im(i).i);
            hold on,
            plot(d(i).ptsCropped(:,:,1),d(i).ptsCropped(:,:,2),'r*');
            for cropR = 1:size(croppedBoxes,1)
                rectangle('position',croppedBoxes(cropR,:));
            end
    %}
end

regs.FRMW.rtdOverX = single([0,0,0,0,0,0]);
fprintff = @fprintf;
calibParams.dfz.rtdOverTanXrange = repmat([-10;10],1,numel(regs.FRMW.rtdOverX))*rtdScale;
calibParams.dfz.rtdOverTanXrange(:,end) = [-150;150];
framesData = d;
warning('off','SPLINES:TPAPS:nonconvergence');
warning('off','SPLINES:TPAPS:longjob');
tpsUndistModel = [];
xbest = [];
    
optionsCropped = defaultDfzOptions; optionsCropped.useCropped = 1;
optDfzOnCropped = @(inputs,tpsModel,x0,runPar) Calibration.aux.calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsCropped);

optionsFull = defaultDfzOptions;
optDfzOnFull = @(inputs,tpsModel,x0,runPar) Calibration.aux.calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsFull);

optionsCroppedRtdOnly = defaultDfzOptions; optionsCroppedRtdOnly.useCropped = 1; optionsCroppedRtdOnly.optimizedParamsStr = 'rtdOnly';
optDfzOnCroppedRtdOnly = @(inputs,tpsModel,x0,runPar) Calibration.aux.calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsCroppedRtdOnly);

optionsfullRtdOnly = defaultDfzOptions; optionsfullRtdOnly.optimizedParamsStr = 'rtdOnly';
optDfzOnFullRtdOnly = @(inputs,tpsModel,x0,runPar) Calibration.aux.calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsfullRtdOnly);

optionsCroppedEval = defaultDfzOptions; optionsCroppedEval.useCropped = 1; optionsCroppedEval.iseval = 1;
evalDfzOnCropped = @(inputs,tpsModel,x0,runPar) Calibration.aux.calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsCroppedEval);

optionsFullEval = defaultDfzOptions; optionsFullEval.iseval = 1;
evalDfzOnFull = @(inputs,tpsModel,x0,runPar) Calibration.aux.calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsFullEval);

optionsFullEvalWithPlanes = defaultDfzOptions; optionsFullEvalWithPlanes.iseval = 1;optionsFullEvalWithPlanes.verbose = 1;
evalDfzOnFullWithPlanes = @(inputs,tpsModel,x0,runPar) Calibration.aux.calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsFullEvalWithPlanes);

    
% Perform DFZ on cropped
[~,resOnCropped,~,xbest] = optDfzOnCropped(framesData(trainImages),[],xbest,[]);
% Calc TPS model to minimize 2D distotion
[~,resFullPreTPS,allVerticesPreTPS] = evalDfzOnFull(framesData(trainImages),[],xbest,[]);
[~,resCroppedPreTPS,croppedVerticesPreTPS] = evalDfzOnCropped(framesData(trainImages),[],xbest,[]);
tpsUndistModel = Calibration.DFZ.calcTPSModel(framesData,croppedVerticesPreTPS,allVerticesPreTPS,runParams);
[~,resOnFullPostTPS,allVerticesPostTPS] = evalDfzOnFull(framesData(trainImages),tpsUndistModel,xbest,[]);
[~,resOncroppedPostTPS,croppedVerticesPostTPS] = evalDfzOnCropped(framesData(trainImages),tpsUndistModel,xbest,[]);
% Optimize System Delay again
[dfzRegs,resOnCroppedPostRtdOpt,~,xbest] = optDfzOnCroppedRtdOnly(framesData(trainImages),tpsUndistModel,xbest,[]);

[~,resFullFinal,allVerticesFinal] = evalDfzOnFullWithPlanes(framesData(trainImages),tpsUndistModel,xbest,runParams);
[~,resCroppedFinal,croppedVerticesFinal] = evalDfzOnCropped(framesData(trainImages),tpsUndistModel,xbest,[]);

gridSize = framesData(1).grid(1:2);
resCropped(1) = calcDfzMetrics(croppedVerticesPreTPS,gridSize);
resCropped(2) = calcDfzMetrics(croppedVerticesPostTPS,gridSize);
resCropped(3) = calcDfzMetrics(croppedVerticesFinal,gridSize);
resCropped(1).Name = 'PreTPS';
resCropped(2).Name = 'PostTPS';
resCropped(3).Name = 'Final';
Tcropped  = dfzResultsToTable( resCropped );

resFull(1) = calcDfzMetrics(allVerticesPreTPS,gridSize);
resFull(2) = calcDfzMetrics(allVerticesPostTPS,gridSize);
resFull(3) = calcDfzMetrics(allVerticesFinal,gridSize);
resFull(1).Name = 'PreTPS';
resFull(2).Name = 'PostTPS';
resFull(3).Name = 'Final';
Tfull  = dfzResultsToTable( resFull );
writetable(Tfull,fullfile(runParams.outputFolder,'AlgoInternal','DFZResults.xlsx'),'WriteRowNames',true,'Sheet', 1);
writetable(Tcropped,fullfile(runParams.outputFolder,'AlgoInternal','DFZResults.xlsx'),'WriteRowNames',true,'Sheet', 2);

results.dfzScaleErrH = resFull(3).meanAbsHorzScaleError;
results.dfzScaleErrV = resFull(3).meanAbsVertScaleError;
results.dfz3DErrH = resFull(3).lineFitMeanRmsErrorTotalHoriz3D;
results.dfz3DErrV = resFull(3).lineFitMeanRmsErrorTotalVertic3D;
results.dfz2DErrH = resFull(3).lineFitMeanRmsErrorTotalHoriz2D;
results.dfz2DErrV = resFull(3).lineFitMeanRmsErrorTotalVertic2D;
results.dfzPlaneFit = resFull(3).rmsPlaneFitDist;
results.geomErr = resFullFinal.geomErr;
    
sDelay = (xbest(3));
    


end


function [ avgRes ,allRes] = calcDfzMetrics( vertices,gridSize )
params.target.squareSize = 30;
params.camera.zMaxSubMM = 4;
params.camera.K = [730.1642         0  541.5000; 0  711.8812  386.0000 ; 0 0 1];% XGA K
params.gridSize = gridSize;

for i = 1:numel(vertices)
    [~, results, ~] = Validation.metrics.gridInterDist([], params, vertices{i});
    orderedResults.meanError = results.meanError;
    orderedResults.meanAbsHorzScaleError = results.meanAbsHorzScaleError;
    orderedResults.meanAbsVertScaleError = results.meanAbsVertScaleError;
    orderedResults.lineFitMeanRmsErrorTotalHoriz3D = results.lineFit.lineFitMeanRmsErrorTotalHoriz3D;
    orderedResults.lineFitMeanRmsErrorTotalVertic3D = results.lineFit.lineFitMeanRmsErrorTotalVertic3D;
    orderedResults.lineFitMeanRmsErrorTotalHoriz3D = results.lineFit.lineFitMeanRmsErrorTotalHoriz3D;
    orderedResults.lineFitMeanRmsErrorTotalVertic3D = results.lineFit.lineFitMeanRmsErrorTotalVertic3D;
    orderedResults.lineFitMeanRmsErrorTotalHoriz2D = results.lineFit.lineFitMeanRmsErrorTotalHoriz2D;
    orderedResults.lineFitMeanRmsErrorTotalVertic2D = results.lineFit.lineFitMeanRmsErrorTotalVertic2D;
    orderedResults.rmsPlaneFitDist = Validation.metrics.planeFitOnCorners([], params, vertices{i});
    allRes(i) = orderedResults;
end
avgRes.meanError = mean([allRes.meanError]);
avgRes.meanAbsHorzScaleError = mean([allRes.meanAbsHorzScaleError]);
avgRes.meanAbsVertScaleError = mean([allRes.meanAbsVertScaleError]);
avgRes.lineFitMeanRmsErrorTotalHoriz3D = mean([allRes.lineFitMeanRmsErrorTotalHoriz3D]);
avgRes.lineFitMeanRmsErrorTotalVertic3D = mean([allRes.lineFitMeanRmsErrorTotalVertic3D]);
avgRes.lineFitMeanRmsErrorTotalHoriz2D = mean([allRes.lineFitMeanRmsErrorTotalHoriz2D]);
avgRes.lineFitMeanRmsErrorTotalVertic2D = mean([allRes.lineFitMeanRmsErrorTotalVertic2D]);
avgRes.rmsPlaneFitDist = mean([allRes.rmsPlaneFitDist]);

end
function [ Ttag ] = dfzResultsToTable( results )

    T = struct2table(results);
    T.Properties.RowNames = T.Name;
    T.Name = [];
    YourArray = table2array(T);
    Ttag = array2table(YourArray.');
    Ttag.Properties.RowNames = T.Properties.VariableNames;
    Ttag.Properties.VariableNames = T.Properties.RowNames;
end

function opt = defaultDfzOptions()
    opt.iseval = 0;
    opt.verbose = 0;
    opt.useCropped = 0;
    opt.optimizedParamsStr = '';
end