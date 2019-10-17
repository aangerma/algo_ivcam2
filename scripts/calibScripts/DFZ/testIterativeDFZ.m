clear
load('C:\temp\unitCalib\F9220056\PC17\mat_files\DFZ_Calib_Calc_in.mat');
load('C:\temp\unitCalib\F9220056\PC17\mat_files\DFZ_im.mat');
runParams.outputFolder = 'C:\temp\unitCalib\F9220056\Periodic';
calibParams = xml2structWrapper('C:\source\algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParamsXGA.xml');
% Prepare the strcut array d. With has the corners data for each CB
% point
captures = {calibParams.dfz.captures.capture(:).type};
shortRangeImages = strcmp('shortRange',captures);
trainImages = strcmp('train',captures);
testImages = strcmp('test',captures);

width = regs.GNRL.imgHsize;
hight = regs.GNRL.imgVsize;
%% find effective image "bounding box"
   % read IR images
% path = fullfile(InputPath,'Pose1');
% im_IR = Calibration.aux.GetFramesFromDir(path,width, hight);
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
% im = GetDFZImages(nof_secne,InputPath,width,hight);

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
    cap = calibParams.dfz.captures.capture(i);
    targetInfo = targetInfoGenerator(cap.target);

    d(i).i = im(i).i;
    d(i).z = im(i).z;

    [pts,colors] = CBTools.findCheckerboardFullMatrix(d(i).i, 1,0,0.2, 1);
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
Calibration.DFZ.saveDFZInputImage(d,runParams);

%% Run 
fprintff = @fprintf;
regs.FRMW.parabRTDFixOverAngy = single([0,0,0]);

warning('off','SPLINES:TPAPS:nonconvergence');
warning('off','SPLINES:TPAPS:longjob');
tpsUndistModel = [];
xbest = [];
calibParamsCropped = calibParams; calibParamsCropped.dfz.calibrateOnCropped = 1;
calibParamsFull = calibParams; calibParamsFull.dfz.calibrateOnCropped = 0;
optDfzOnCropped = @(inputs,tpsModel,x0) Calibration.aux.calibDFZ(inputs,regs,calibParamsCropped,fprintff,0,0,x0,[],tpsModel); 
optDfzOnFull = @(inputs,tpsModel,x0) Calibration.aux.calibDFZ(inputs,regs,calibParamsFull,fprintff,0,0,x0,[],tpsModel); 
optDfzOnCroppedRtdOnly = @(inputs,tpsModel,x0) Calibration.aux.calibDFZ(inputs,regs,calibParamsCropped,fprintff,0,0,x0,[],tpsModel,'rtdOnly'); 
optDfzOnFullRtdOnly = @(inputs,tpsModel,x0) Calibration.aux.calibDFZ(inputs,regs,calibParamsFull,fprintff,0,0,x0,[],tpsModel,'rtdOnly'); 
evalDfzOnCropped = @(inputs,tpsModel,x0) Calibration.aux.calibDFZ(inputs,regs,calibParamsCropped,fprintff,0,1,x0,[],tpsModel); 
evalDfzOnFull = @(inputs,tpsModel,x0) Calibration.aux.calibDFZ(inputs,regs,calibParamsFull,fprintff,0,1,x0,[],tpsModel); 
% calibParams.dfz.calibFullAfterCropped = 1;
fprintff('        %-15s|%-15s|%-15s\n','Cropped'...
    ,'FullPostTPS'...
    ,'FullPostRtdOpt');
dbgData.parabRTDFixOverAngy = regs.FRMW.parabRTDFixOverAngy;

for iter = 1:5
    % Copy original d:
    framesData = d;
    % Perform DFZ on center
    [~,resOnCropped,~,xbest] = optDfzOnCropped(framesData(trainImages),[],xbest);
    % Perform DFZ on all
%         if calibParams.dfz.calibFullAfterCropped
%             [~,resOnFullPreTPS,~,xbest] = optDfzOnFull(framesData(trainImages),[],xbest);
%         end
    % Calc TPS model to minimize 2D distotion
    [~,~,allVertices] = evalDfzOnFull(framesData(trainImages),[],xbest);
    [~,~,croppedVertices] = evalDfzOnCropped(framesData(trainImages),[],xbest);
    tpsUndistModel = Calibration.DFZ.calcTPSModel(framesData,croppedVertices,allVertices,runParams);
    [~,resOnFullPostTPS] = evalDfzOnFull(framesData(trainImages),tpsUndistModel,xbest);
    % Optimize System Delay again Plus RTD parabola over angy
    [dfzRegs,resOnCroppedPostRtdOpt,~,xbest] = optDfzOnCroppedRtdOnly(framesData(trainImages),tpsUndistModel,xbest);       

    fprintff('Iter %2d:%15.2g|%15.2g|%15.2g\n',iter,resOnCropped.geomErr,resOnFullPostTPS.geomErr,resOnCroppedPostRtdOpt.geomErr);
    dbgData.parabRTDFixOverAngy(end+1,:) = dfzRegs.FRMW.parabRTDFixOverAngy;
%     dbgData.metrics(end+1) = calc3DMetrics;
end
