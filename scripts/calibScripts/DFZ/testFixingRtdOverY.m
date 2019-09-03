load('C:\temp\unitCalib\F9220005\PC26\mat_files\DFZ_Calib_Calc_in.mat');
load('C:\temp\unitCalib\F9220005\PC26\mat_files\DFZ_im.mat');
runParams.outputFolder = 'C:\temp\unitCalib\F9220005\PC_Test';
calibParams = xml2structWrapper('C:\source\algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParamsXGA.xml');% Prepare the strcut array d. With has the corners data for each CB
calibParams.dfz.cropRatios = [0.2 0.0005;0.0005 0.2];
captures = {'train'};
captures(2:5) = captures(1);
captures{6} = 'test';
captures(7:20) = captures(6);
captures(12) = {'shortRange'};
% 
% im([53,18,20,11,3]) = im([52,17,19,10,2]);
% im(12) = im(11);
% for i = 1:50
%    tabplot(i);
%    imagesc(im(i).i)
% end

% point
shortRangeImages = strcmp('shortRange',captures);
trainImages = strcmp('train',captures);
testImages = strcmp('test',captures);

% trainImages = zeros(size(trainImages)); trainImages([19,50,27,26,18]) = logical(1);
% testImages = ones(size(trainImages),'logical');

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
        [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(d(i).i, 1,0,0.2, 1);
    catch
        [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(d(i).i, 1);
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
    [d(i).rpt,pts,colors] = Calibration.aux.samplePointsRtdAdvanced(im(i).z,pts,regs,colors,0,calibParams.dfz.sampleRTDFromWhiteCheckers);
    
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
% Calibration.DFZ.saveDFZInputImage(d,runParams);


%% Run the DFZ 
%%%% optional
if 0
    calibParams.dfz.polyVarRange = [-200,-200,-10;200,200,10];
    calibParams.dfz.fovexTangentRange = zeros(size(calibParams.dfz.fovexTangentRange));
    calibParams.dfz.fovexNominalRange = [DFZ_regs.FRMWfovexNominal;DFZ_regs.FRMWfovexNominal];
end
calibParams.dfz.fovexRadialRange = zeros(size(calibParams.dfz.fovexRadialRange));
calibParams.dfz.rtdOverTanYrange = [-50,-50,-50,-50,-50,-50; 50, 50, 50,50, 50, 50];
regs.FRMW.rtdOverY = single([0,0,0,0,0,0]);
%%%%

gridSize =[20,28];
fprintff = @fprintf;
framesData = d;
defaultDfzOptions.iseval = 0;
defaultDfzOptions.verbose = 0;
defaultDfzOptions.useCropped = 0;
defaultDfzOptions.optimizedParamsStr = '';
warning('off','SPLINES:TPAPS:nonconvergence');
warning('off','SPLINES:TPAPS:longjob');
tpsUndistModel = [];
xbest = [];
optionsCropped = defaultDfzOptions; optionsCropped.useCropped = 1;
optDfzOnCropped = @(inputs,tpsModel,x0,runPar) calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsCropped);

optionsFull = defaultDfzOptions;
optDfzOnFull = @(inputs,tpsModel,x0,runPar) calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsFull);

optionsCroppedRtdOnly = defaultDfzOptions; optionsCroppedRtdOnly.useCropped = 1; optionsCroppedRtdOnly.optimizedParamsStr = 'rtdOnly';
optDfzOnCroppedRtdOnly = @(inputs,tpsModel,x0,runPar) calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsCroppedRtdOnly);

optionsfullRtdOnly = defaultDfzOptions; optionsfullRtdOnly.optimizedParamsStr = 'rtdOnly';
optDfzOnFullRtdOnly = @(inputs,tpsModel,x0,runPar) calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsfullRtdOnly);

optionsCroppedEval = defaultDfzOptions; optionsCroppedEval.useCropped = 1; optionsCroppedEval.iseval = 1;
evalDfzOnCropped = @(inputs,tpsModel,x0,runPar) calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsCroppedEval);

optionsFullEval = defaultDfzOptions; optionsFullEval.iseval = 1;
evalDfzOnFull = @(inputs,tpsModel,x0,runPar) calibDFZ(inputs,regs,calibParams,fprintff,x0,runPar,tpsModel,optionsFullEval);

if calibParams.dfz.performRegularDFZWithoutTPS
    [dfzRegs,res,allVertices] = optDfzOnFull(framesData(trainImages),[],xbest,runParams);
    results.geomErr = res.geomErr;
else
    
    % Perform DFZ on cropped
    [~,resOnCropped,~,xbest] = optDfzOnCropped(framesData(trainImages),[],xbest,[]);
%     if calibParams.dfz.calibFullAfterCropped % Perform DFZ on all
%         [~,~,~,xbest] = optDfzOnFull(framesData(trainImages),[],xbest,[]);
%     end
    % Calc TPS model to minimize 2D distotion
    [~,resFullPreTPS,allVerticesPreTPS] = evalDfzOnFull(framesData(trainImages),[],xbest,[]);
    [~,resCroppedPreTPS,croppedVerticesPreTPS] = evalDfzOnCropped(framesData(trainImages),[],xbest,[]);
    tpsUndistModel = Calibration.DFZ.calcTPSModel(framesData,croppedVerticesPreTPS,allVerticesPreTPS,runParams);
    [~,resOnFullPostTPS,allVerticesPostTPS] = evalDfzOnFull(framesData(trainImages),tpsUndistModel,xbest,[]);
    [~,resOncroppedPostTPS,croppedVerticesPostTPS] = evalDfzOnCropped(framesData(trainImages),tpsUndistModel,xbest,[]);
    % Optimize System Delay again
    [dfzRegs,resOnCroppedPostRtdOpt,~,xbest] = optDfzOnCroppedRtdOnly(framesData(trainImages),tpsUndistModel,xbest,[]);
    
    [~,resFullFinal,allVerticesFinal] = evalDfzOnFull(framesData(trainImages),tpsUndistModel,xbest,runParams);
    [~,resCroppedFinal,croppedVerticesFinal] = evalDfzOnCropped(framesData(trainImages),tpsUndistModel,xbest,[]);
    
    
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

end

%% Perform undistort in R
verticesFull = allVerticesFinal;
verticesCropped = croppedVerticesFinal;
verticesRef = framesData(1).pts3d;

for k = 1:numel(verticesFull)
    vNoNans = verticesFull{1,k};
    noNanVertices = ~isnan(vNoNans(:,1));
    vNoNans = vNoNans(noNanVertices,:);
    vRef = verticesRef;
    vRef = vRef(noNanVertices,:);
    [~,vFit{1,k}] = Calibration.aux.rigidFit(vNoNans,vRef);
    vFull{1,k} = vNoNans;
end


vFit = cell2mat(vFit');
vFull = cell2mat(vFull');
vFullNew = vfitProjOnV(vFull,vFit);

% calculate R fix per tanx tany

tanxy = [vFull(:,1)./vFull(:,3) vFull(:,2)./vFull(:,3)];
addedR = sqrt(sum(vFullNew.^2,2)) - sqrt(sum(vFull.^2,2));
tpsRUndistModel = tpaps(tanxy',addedR');
avals = fnval(tpsRUndistModel,tanxy');

%% Eval errors with undist R
for k = 1:numel(verticesFull)
    v = verticesFull{1,k};
    tanxy = [v(:,1)./v(:,3) v(:,2)./v(:,3)];
    addedR = fnval(tpsRUndistModel,tanxy');
    normV = sqrt(sum(v.^2,2));
    verticesAfterRFix{1,k} =  normr(v).*(normV + addedR');
    
    vC = verticesCropped{1,k};
    tanxy = [vC(:,1)./vC(:,3) vC(:,2)./vC(:,3)];
    addedR = fnval(tpsRUndistModel,tanxy');
    normV = sqrt(sum(vC.^2,2));
    verticesAfterRFixCropped{1,k} =  normr(vC).*(normV + addedR');
end

tmpRes = calcDfzMetrics(verticesAfterRFix,gridSize);
tmpRes.Name = 'afterTPSinR';
resFull(4) = tmpRes;
Tfull  = dfzResultsToTable( resFull );

tmpRes = calcDfzMetrics(verticesAfterRFixCropped,gridSize);
tmpRes.Name = 'afterTPSinR';
resCropped(4) = tmpRes;
Tcropped  = dfzResultsToTable( resCropped );

% Test Images
dtest = d(testImages);
dtest(8) = [];
[~,~,testVerticesCropped] = evalDfzOnCropped(dtest,tpsUndistModel,xbest,[]);
[~,~,testVertices] = evalDfzOnFull(dtest,tpsUndistModel,xbest,[]);
tmpRes = calcDfzMetrics(testVertices,gridSize);
tmpRes.Name = 'test';
resFull(5) = tmpRes;
tmpRes = calcDfzMetrics(testVerticesCropped,gridSize);
tmpRes.Name = 'test';
resCropped(5) = tmpRes;

for k = 1:numel(testVertices)
    v = testVertices{1,k};
    tanxy = [v(:,1)./v(:,3) v(:,2)./v(:,3)];
    addedR = fnval(tpsRUndistModel,tanxy');
    normV = sqrt(sum(v.^2,2));
    testVerticesAfterRFix{1,k} =  normr(v).*(normV + addedR');
    
    vC = testVerticesCropped{1,k};
    tanxy = [vC(:,1)./vC(:,3) vC(:,2)./vC(:,3)];
    addedR = fnval(tpsRUndistModel,tanxy');
    normV = sqrt(sum(vC.^2,2));
    testVerticesAfterRFixCropped{1,k} =  normr(vC).*(normV + addedR');
end

tmpRes = calcDfzMetrics(testVerticesAfterRFix,gridSize);
tmpRes.Name = 'testAfterTPSinR';
resFull(6) = tmpRes;
Tfull  = dfzResultsToTable( resFull );

tmpRes = calcDfzMetrics(testVerticesAfterRFixCropped,gridSize);
tmpRes.Name = 'testAfterTPSinR';
resCropped(6) = tmpRes;
Tcropped  = dfzResultsToTable( resCropped );

figure,
[tmpRes,all] = calcDfzMetrics(testVerticesAfterRFix,gridSize);
mname = {'meanError';'meanAbsHorzScaleError';'meanAbsVertScaleError';'lineFitMeanRmsErrorTotalHoriz3D';'lineFitMeanRmsErrorTotalVertic3D';'lineFitMeanRmsErrorTotalHoriz2D';'lineFitMeanRmsErrorTotalVertic2D';'rmsPlaneFitDist'};
for f = 1:8
   tabplot;
   plot([all.(mname{f})]);
   title(mname{f});
end
% 
% [tanX,tanY] = meshgrid(linspace(-tand(40),tand(40),500),linspace(-tand(40),tand(40),500));
% vv = [tanX(:),tanY(:),ones(size(tanY(:)))];
% addedRR = fnval(tpsRUndistModel,[tanX(:),tanY(:)]');
% imagesc(reshape(addedRR,500,500))
% 
% 
% params.camera.K = [730.1642         0  541.5000; 0  711.8812  386.0000 ; 0 0 1];% XGA K
% vpix = params.camera.K*(vv');
% gg = griddedInterpolant(reshape(vpix(1,:)',500,500)',reshape(vpix(2,:)',500,500)',reshape(addedRR,500,500)');
% [yq,xq] = ndgrid(1:768,1:1024);
% vq = gg(xq,yq);
% imagesc(vq);colorbar;