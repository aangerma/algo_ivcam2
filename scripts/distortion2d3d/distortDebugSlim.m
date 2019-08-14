loadPath = {'\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2236\F9240031\Algo1 3.03.0\Algo\mat_files';...
    '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2311\F9240032\ALGO1 3.03.0\mat_files';...
    '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2311\F9240073\Algo1 3.03.0\mat_files';...
    '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2318\F9240021\Algo1 3.03.0 cal\mat_files'};%...
%     '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2318\F9240067\Algo1 3.03.0\mat_files'};
%savePath = 'X:\Data\distortion\3Images'; 
% savePath = 'D:\Data\Ivcam2\Dist2D3D\';
savePath = 'D:\Data\Ivcam2\Dist2D3D\K\';
unitsNum = cell(length(loadPath),1);

nonRectangleFlag = true;
for ixRun = 1:length(loadPath)
    ixUnit = strfind(loadPath{ixRun,1},'F');
    unitsNum{ixRun,1} =  loadPath{ixRun,1}(ixUnit:ixUnit+7);
    dirName = [savePath '\run' num2str(ixRun)];
    mkdir(dirName);
    [calibParams, DFZ_regs,InputPath, regs, d, fprintff, runParams] = prepareDataForReplay(loadPath{ixRun,1}, nonRectangleFlag);
    disp([datestr(datetime) ' - starting run ' num2str(ixRun) '/' num2str(length(loadPath))]);
    filePrefix = num2str(ixRun);
    resultsT = runDistortionFixAnalysis(calibParams, DFZ_regs, regs, d, fprintff, runParams,dirName, filePrefix);
    disp([datestr(datetime) ' - finished run ' num2str(ixRun) '/' num2str(length(loadPath))]);
    resultsT = [repelem(unitsNum(ixRun,1),size(resultsT,1))'  resultsT];
    if ixRun == 1
        allResultsT = resultsT;
    else
        allResultsT = [allResultsT; resultsT];
    end
end
writetable(resultsT, [savePath '\totResultTable.xlsx']);
save([savePath '\unitNumbers.mat', 'unitsNum']);
%%
% Main function
function [resultsT] = runDistortionFixAnalysis(calibParams, DFZ_regs, regs, d, fprintff, runParams,savePath, filePrefix)
%%
checkerSize = [20,28,3];
imIx = [1,2,3,4,5];
doDebug = false;
doEval = false;
calibParams.dfz.doCroppedAreaInCalibDFZ = 0;
% Run like today
[todayRegs,todayResults,allVerticesToday] = Calibration.aux.calibDFZ(d(imIx),regs,calibParams,fprintff,0,doEval,[],runParams);
resultsT = struct2table(todayResults);
nameCol = {'Today (4)'};

%%
% Get cropped vertices
doEval = false;
calibParams.dfz.doCroppedAreaInCalibDFZ = 1;
[dfzRegs,resultsOnCropped,allVerticesCropped] = Calibration.aux.calibDFZ(d(imIx),regs,calibParams,fprintff,0,doEval,[],runParams);
resultsT = [resultsT; struct2table(resultsOnCropped)];
nameCol = [nameCol; 'DFZ on cropped (0)'];

%%
regsWithDFZres = regs;
intersectFieldsFRMW=intersect(fieldnames(dfzRegs.FRMW),fieldnames(regs.FRMW));
intersectFieldsDEST=intersect(fieldnames(dfzRegs.DEST),fieldnames(regs.DEST));
for k = 1:length(intersectFieldsFRMW)
    regsWithDFZres.FRMW.(intersectFieldsFRMW{k}) = dfzRegs.FRMW.(intersectFieldsFRMW{k});
end
for k = 1:length(intersectFieldsDEST)
    regsWithDFZres.DEST.(intersectFieldsDEST{k}) = dfzRegs.DEST.(intersectFieldsDEST{k});
end
% Run eval with registers from DFZ run
doEval = true; % eval is always on full so no need to calibParams.dfz.doCroppedAreaInCalibDFZ = 0;
[~,resultsEvalOnFullAfterDfzWithCropped,allVertices] = Calibration.aux.calibDFZ(d(imIx),regsWithDFZres,calibParams,fprintff,0,doEval,[],runParams);
resultsT = [resultsT; struct2table(resultsEvalOnFullAfterDfzWithCropped)];
nameCol = [nameCol; 'DFZ on cropped and eval on full (1)'];

%%
% Run DFZ on all vertices after DFZ on cropped
% doEval = false;
% calibParams.dfz.doCroppedAreaInCalibDFZ = 0;
% [~,resultsOnFullAfterDfzWithCropped,allVerticesAfterDfzWithCropped] = Calibration.aux.calibDFZ(d(imIx),regsWithDFZres,calibParams,fprintff,0,doEval,[],runParams);
% resultsT = [resultsT; struct2table(resultsOnFullAfterDfzWithCropped)];
% nameCol = [nameCol; 'DFZ on cropped and then DFZ on full (5)'];

%%
% Calc fitted vertices fKfor2dErroror cropped area, normalize and create model
rotmatAll = zeros(length(allVerticesCropped),3,3);
shiftAll = zeros(length(allVerticesCropped),1,3);
meanValAll = zeros(length(allVerticesCropped),1,3);

for k = 1:length(allVerticesCropped)
    % Get rid off NaNs
    v = allVerticesCropped{1,k};
    [rows,cols,vNoNanCropped] = getVerticesWithoutNans(allVerticesCropped{1,k},checkerSize);
    % Adjust the checker points to match the vertices points in the cropped area
    vCheckerCropped = reshape(d(k).pts3d,20,28,3);
    vCheckerCropped = vCheckerCropped(rows,cols,:);
    vCheckerCropped = reshape(vCheckerCropped,[],3);
    %     vCheckerCropped(:,3) = vCheckerCropped(:,3) + depth;
    % Calculate rotation and shift of rigid fit for cropped points
    [~,~,rotmat,shiftVec, meanVal] = Calibration.aux.rigidFit(vNoNanCropped,vCheckerCropped);
    rotmatAll(k,:,:) = rotmat;
    shiftAll(k,:,:) = shiftVec;
    meanValAll(k,:,:) = meanVal;
    
    
    [pts1_vFullFromEval,pts2_vFullFromEval] = createPtsForPtsModel(allVertices{1,k},d(k).pts3d,meanVal,rotmat,shiftVec,checkerSize);
%     [pts1_vFullFromDFZ,pts2_vFullFromDFZ] = createPtsForPtsModel(allVerticesAfterDfzWithCropped{1,k},d(k).pts3d,meanVal,rotmat,shiftVec,checkerSize);
    %{
    % Get the vertices that are not NaN (not cropped)
    [rows,cols,vNoNan] = getVerticesWithoutNans(allVertices{1,k},checkerSize);
    % Perform rotation and scale to the 3D points to get the fitted vertices and normalize to a unit vector
    %     vFitUnit = normr((vNoNan-meanVal)*rotmat'+c);
    vChecker = reshape(d(k).pts3d,20,28,3);
    vChecker = vChecker(rows,cols,:);
    vChecker = reshape(vChecker,[],3);
    %     vChecker(:,3) = vChecker(:,3) + depth;
    vFitUnit = (vChecker-meanVal)*rotmat'+shiftVec;
    
    % Take the same points in the result vertices and normalize them too
    vResultUnit = vNoNan;
    
    % Prepare points for createTpsUndistModel function
    if k == 1
        pts1 = [vResultUnit(:,1)./vResultUnit(:,3), vResultUnit(:,2)./vResultUnit(:,3)]';
        pts2 = [vFitUnit(:,1)./vFitUnit(:,3), vFitUnit(:,2)./vFitUnit(:,3)]';
    else
        pts1 = [pts1,[vResultUnit(:,1)./vResultUnit(:,3), vResultUnit(:,2)./vResultUnit(:,3)]'];
        pts2 = [pts2,[vFitUnit(:,1)./vFitUnit(:,3), vFitUnit(:,2)./vFitUnit(:,3)]'];
    end
    %}
    if doDebug
        figure;
        allV = allVertices{1,k};
        scatter3(allV(:,1),allV(:,2),allV(:,3),'r');
        croppedV = allVerticesCropped{1,k};
        hold on; scatter3(croppedV(:,1),croppedV(:,2),croppedV(:,3),'bx');
        legend('All v from DFZcalib', 'Cropped V from DFZcalib');
        xlabel('x'); ylabel('y');zlabel('z');
        
        figure;
        scatter3(vNoNan(:,1),vNoNan(:,2),vNoNan(:,3),'r');
        hold on; scatter3(vNoNanCropped(:,1),vNoNanCropped(:,2),vNoNanCropped(:,3),'bx');
        legend('vNoNan', 'vNoNanCropped');
        xlabel('x'); ylabel('y');zlabel('z');
        
        figure;
        scatter3(vFitUnit(:,1),vFitUnit(:,2),vFitUnit(:,3),'r');
        hold on;
        scatter3(vResultUnit(:,1),vResultUnit(:,2),vResultUnit(:,3),'bx');
        legend('vFitUnit', 'vResultUnit');
        xlabel('x'); ylabel('y');zlabel('z');
        
        allV = (vChecker-meanVal)*rotmat'+shiftVec;
        figure; scatter3(allV(:,1),allV(:,2),allV(:,3),'r');
        debugVar = reshape(vChecker,[],3);
        hold on; scatter3(debugVar(:,1),debugVar(:,2),debugVar(:,3),'gx');
        allV = allVertices{1,k};
        scatter3(allV(:,1),allV(:,2),allV(:,3),'k');
        croppedV = (vCheckerCropped-meanVal)*rotmat'+shiftVec;
        scatter3(croppedV(:,1),croppedV(:,2),croppedV(:,3),'bs');
        legend('pts3d fitted', 'pts3d', 'All vertices from DFZ','pts3d cropped fitted');
        xlabel('x'); ylabel('y');zlabel('z');
    end
end
if doDebug
    figure;
    scatter(pts1_vFullFromEval(1,:),pts1_vFullFromEval(2,:),'r');
    hold on; scatter(pts2_vFullFromEval(1,:),pts2_vFullFromEval(2,:),'bx');
    legend('pts1', 'pts2');
    xlabel('x'); ylabel('y');
end
% Calculate model
tpsUndistModel_vFullFromEval= Calibration.Undist.createTpsUndistModel(pts1_vFullFromEval,pts2_vFullFromEval);
% tpsUndistModel_vFullFromDFZ = Calibration.Undist.createTpsUndistModel(pts1_vFullFromDFZ,pts2_vFullFromDFZ);

%%
if doDebug
    % Fix vertices
    for k = 1:length(allVertices)
        [rows,cols,vNoNan] = getVerticesWithoutNans(allVertices{1,k},checkerSize);
        vPostTps = Calibration.Undist.undistByTPSModel(normr(vNoNan),tpsUndistModel_vFullFromEval);
        % Restore the un-normalized vertices
        sing = vPostTps(:,2);
        rpt = d(imIx(k)).rpt;
        rpt = reshape(rpt,20,28,3);
        rpt = rpt(rows,cols,:);
        rpt = reshape(rpt,[],3);
        rtd_=rpt(:,1)-regsWithDFZres.DEST.txFRQpd(1);
        r = (0.5*(rtd_.^2 - regsWithDFZres.DEST.baseline2))./(rtd_ - regsWithDFZres.DEST.baseline.*sing);
        vFixed = double(vPostTps.*r);
        figure; title('V result (red) V post interpulation (green)'); hold on; scatter3(vNoNan(:,1),vNoNan(:,2),vNoNan(:,3),'r');
        scatter3(vFixed(:,1),vFixed(:,2),vFixed(:,3),'g'); quiver3(vFixed(:,1),vFixed(:,2),vFixed(:,3),vNoNan(:,1)-vFixed(:,1),vNoNan(:,2)-vFixed(:,2),vNoNan(:,3)-vFixed(:,3));
    end
end
%%
% Check errors with TPS correction
% doEval = true;
% [~,resultsDFZcroppedAndTps,allVerticesDFZcroppedAndTps] = Calibration.aux.calibDFZ(d(imIx),regsWithDFZres,calibParams,fprintff,0,doEval,[],runParams,tpsUndistModel_vFullFromEval);
% resultsT = [resultsT; struct2table(resultsDFZcroppedAndTps)];
% nameCol = [nameCol; 'DFZ on cropped and then DFZ eval with TPS on Full (2)'];

%%
% doEval = false;
% calibParams.dfz.doCroppedAreaInCalibDFZ = 0;
% [~,resultsDFZcroppedDfzFullTpsDfz,allVerticesDFZcroppedDfzFullTpsDfz] = Calibration.aux.calibDFZ(d(imIx),regsWithDFZres,calibParams,fprintff,0,doEval,[],runParams,tpsUndistModel_vFullFromDFZ);
% resultsT = [resultsT; struct2table(resultsDFZcroppedDfzFullTpsDfz)];
% nameCol = [nameCol; 'DFZ on cropped and then DFZ full and TPS with DFZ (7)'];


%%
doEval = false;
calibParams.dfz.doCroppedAreaInCalibDFZ = 0;
[finalDfzRegs,resultsDFZcroppedTpsNdfzFull,allVerticesDFZcroppedTpsNdfzFull] = Calibration.aux.calibDFZ(d(imIx),regsWithDFZres,calibParams,fprintff,0,doEval,[],runParams,tpsUndistModel_vFullFromEval);
resultsT = [resultsT; struct2table(resultsDFZcroppedTpsNdfzFull)];
nameCol = [nameCol; 'DFZ on cropped and then DFZ full with TPS (3)'];
resultsT = [nameCol, resultsT];

%%

finalRegs = regs;
intersectFieldsFRMW=intersect(fieldnames(finalDfzRegs.FRMW),fieldnames(regs.FRMW));
intersectFieldsDEST=intersect(fieldnames(finalDfzRegs.DEST),fieldnames(regs.DEST));
for k = 1:length(intersectFieldsFRMW)
    finalRegs.FRMW.(intersectFieldsFRMW{k}) = finalDfzRegs.FRMW.(intersectFieldsFRMW{k});
end
for k = 1:length(intersectFieldsDEST)
    finalRegs.DEST.(intersectFieldsDEST{k}) = finalDfzRegs.DEST.(intersectFieldsDEST{k});
end
for ii = 1:length(d)-1
    dout(ii).i = spherical2regularIR(d(imIx(ii)).i, regs, tpsUndistModel_vFullFromEval);
    corners = Calibration.aux.CBTools.findCheckerboardFullMatrix(dout(ii).i,1,[],[],true);
    rectCorners = Calibration.aux.CBTools.findCheckerboardFullMatrix(dout(ii).i,1,[],[],false);
    figure(1)
    subplot(2,2,ii)
    imagesc(dout(ii).i)
    hold on
    plot(vec(corners(:,:,1)), vec(corners(:,:,2)), 'r.')
    validRows = find(any(~isnan(rectCorners(:,:,1)),2));
    validCols = find(any(~isnan(rectCorners(:,:,1)),1));
    TL = squeeze(rectCorners(validRows(1), validCols(1),:));
    TR = squeeze(rectCorners(validRows(1), validCols(end),:));
    BL = squeeze(rectCorners(validRows(end), validCols(1),:));
    BR = squeeze(rectCorners(validRows(end), validCols(end),:));
    plot([TL(1),TR(1),BR(1),BL(1),TL(1)], [TL(2),TR(2),BR(2),BL(2),TL(2)],'m-','linewidth', 1)
end

%%
% Save workspace
save([savePath '\workspaceVars.mat']);
writetable(resultsT, [savePath '\resultTable' filePrefix '.xlsx']);
end
%%
% Helper functions:
function [calibParams, DFZ_regs,InputPath, regs, d, fprintff, runParams] = prepareDataForReplay(loadPath, nonRectangleFlag)
% load('\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2236\F9240031\Algo1 3.03.0\Algo\mat_files\DFZ_Calib_Calc_in.mat');
% load('\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2236\F9240031\Algo1 3.03.0\Algo\mat_files\DFZ_im.mat');
load([loadPath '\DFZ_Calib_Calc_in.mat'], 'calibParams', 'DFZ_regs', 'InputPath', 'regs');
load([loadPath '\DFZ_im.mat'], 'im');


%% DFZ Calib Calc
calibParams.dfz.gammaVertical = 2;
calibParams.dfz.gammaHorizon = 2;
calibParams.dfz.doCroppedAreaInCalibDFZ = 0;
% calibParams.dfz.fovexTangentRange = [-1,-1;1,1];
calibParams.dfz.Kfor2dError = [439.7540 0 319.5;0 450.4340 239.5;0 0 1];
calibParams.dfz.sampleRTDFromWhiteCheckers = true;
calibPassed = 0;
captures = {calibParams.dfz.captures.capture(:).type};
shortRangeImages = strcmp('shortRange',captures);
trainImages = strcmp('train',captures);
testImages = strcmp('test',captures);

width = regs.GNRL.imgHsize;
hight = regs.GNRL.imgVsize;
%% find effective image "bounding box"
% read IR images
path = fullfile(InputPath,'Pose1');
% im_IR = Calibration.aux.GetFramesFromDir(path,width, hight);
IR_image = im(1).i; %Calibration.aux.average_images(im_IR(:,:,(1:10)));
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
cropRatioX = calibParams.dfz.cropRatio(1);
cropRatioY = calibParams.dfz.cropRatio(2);
croppedBbox = bbox;
croppedBbox(1) = croppedBbox(1) + cropRatioX*croppedBbox(3);
croppedBbox(3) = (1-2*cropRatioX)*croppedBbox(3);
croppedBbox(2) = croppedBbox(2) + cropRatioY*croppedBbox(4);
croppedBbox(4) = (1-2*cropRatioY)*croppedBbox(4);
%croppedBbox = int32(croppedBbox);
for i = 1:nof_secne
    cap = calibParams.dfz.captures.capture(i);
    targetInfo = targetInfoGenerator(cap.target);
    
    d(i).i = im(i).i;
    d(i).z = im(i).z;
    
    [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(d(i).i, 1, [], [], nonRectangleFlag);
    if all(isnan(pts(:)))
        error('Error! Checkerboard detection failed on image %d!',i);
    end
    grid = [size(pts,1),size(pts,2),1];
    %       [pts,grid] = Validation.aux.findCheckerboard(im(i).i,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    %        grid(end+1) = 1;
    targetInfo.cornersX = grid(1);
    targetInfo.cornersY = grid(2);
    
    
    %        d(i).c = im(i).c;
    d(i).pts = pts;
    d(i).colors = colors;
    d(i).grid = grid;
    d(i).pts3d = create3DCorners(targetInfo)';
%     d(i).rpt = Calibration.aux.samplePointsRtd(im(i).z,pts,regs);
    d(i).rpt = Calibration.aux.samplePointsRtdAdvanced(im(i).z,pts,regs,colors,0,calibParams.dfz.sampleRTDFromWhiteCheckers);
    

    imCropped = zeros(size(im(i).i));
    imCropped(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3)) = ...
        im(i).i(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3));
    %             [ptsCropped, gridCropped] = detectCheckerboard(imCropped);
    [ptsCropped,colorsCropped] = Calibration.aux.CBTools.findCheckerboardFullMatrix(imCropped, 1, [], [], nonRectangleFlag);
    gridCropped = [size(ptsCropped,1),size(ptsCropped,2),1];
%       [ptsCropped,gridCropped] = Validation.aux.findCheckerboard(imCropped,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    gridCropped(end+1) = 1;
    
%     
%     outOfBoxIdxs = pts(:,:,1)< croppedBbox(1) | pts(:,:,1)>(croppedBbox(1)+croppedBbox(3)) | ...
%         pts(:,:,2)<croppedBbox(2) | pts(:,:,2)>(croppedBbox(2)+croppedBbox(4));
%     ptsCropped1 = d(i).pts(:,:,1);
%     ptsCropped2 = d(i).pts(:,:,2);
%     ptsCropped1(outOfBoxIdxs)= NaN;
%     ptsCropped2(outOfBoxIdxs)= NaN;
%     ptsCropped = cat(3,ptsCropped1,ptsCropped2);
    
    rptCropped  = Calibration.aux.samplePointsRtd(im(i).z,ptsCropped,regs);
    
    d(i).ptsCropped = ptsCropped;
    d(i).gridCropped = d(i).grid;
    d(i).rptCropped = rptCropped;
end
d = d([1,3,4,5,6]);
% runParams.outputFolder = OutputDir;
% Calibration.DFZ.saveDFZInputImage(d,runParams);
% dodluts=struct;
%% Collect stats  dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov
% if 0 % TEMP: initialize new parameters that are not saved in old recordings
%     regs.FRMW.undistAngHorz=zeros(1,4,'single'); regs.FRMW.undistAngVert=zeros(1,4,'single'); regs.FRMW.fovexNominal=single([0.080740546190841,0.003021202017618,-0.000127636017763,0.000003583535017]); regs.FRMW.fovexExistenceFlag=true; regs.FRMW.fovexLensDistFlag=true; regs.FRMW.fovexRadialK=zeros(1,3,'single'); regs.FRMW.fovexTangentP=zeros(1,2,'single'); regs.FRMW.fovexCenter=zeros(1,2,'single');
%     %calibParams.dfz.fovxRange=[40,80]; calibParams.dfz.fovyRange=[35,65]; calibParams.dfz.zenithxRange=[0,0]; calibParams.dfz.zenithyRange=[0,0]; calibParams.dfz.polyVarRange=[-200;200]*[0,1,0]; calibParams.dfz.pitchFixFactorRange=[-150,150]; calibParams.dfz.undistHorzRange=[-100;100]*ones(1,4); calibParams.dfz.undistVertRange=[-100;100]*ones(1,4); calibParams.dfz.fovexNominalRange=[-1;1]*ones(1,4); calibParams.dfz.fovexRadialRange=[-100;100]*ones(1,3); calibParams.dfz.fovexTangentRange=[-100;100]*ones(1,2); calibParams.dfz.fovexCenterRange=[-100;100]*ones(1,2);
%     calibParams.dfz.delayRange=[5000,5500]; calibParams.dfz.fovxRange=[60,75]; calibParams.dfz.fovyRange=[55,65]; calibParams.dfz.zenithxRange=[0,0]; calibParams.dfz.zenithyRange=[0,0]; calibParams.dfz.polyVarRange=[0;200]*[0,1,0]; calibParams.dfz.pitchFixFactorRange=[-200,100]; calibParams.dfz.undistHorzRange=[-100;100]*ones(1,4); calibParams.dfz.undistVertRange=[-50;50]*ones(1,4); calibParams.dfz.fovexNominalRange=[-0.1,-0.01,-0.001,0.000003;0.1,0.01,0.001,0.000004]; calibParams.dfz.fovexRadialRange=[-1;1]*ones(1,3); calibParams.dfz.fovexTangentRange=[-1;1]*ones(1,2); calibParams.dfz.fovexCenterRange=[-5;5]*ones(1,2);
%     regs.DEST.txFRQpd=single([1 1 1]*5250); regs.FRMW.xfov=single(67.5)*ones(1,5,'single'); regs.FRMW.yfov=single(60)*ones(1,5,'single'); regs.FRMW.polyVars=single([0,100,0]); regs.FRMW.pitchFixFactor=single(-50);
fprintff=@fprintf;
runParams = [];
%     runParams.outputFolder='D:\Data\Ivcam2\FOVex\temp';
% end
% calibParams.dfz.... =

end



function [pts1,pts2] = createPtsForPtsModel(vertices,pts3d,meanVal,rotmat,shiftVec,checkerSize)
% Get the vertices that are not NaN (not cropped)
[rows,cols,vResult] = getVerticesWithoutNans(vertices,checkerSize);
% Perform rotation and scale to the 3D points to get the fitted vertices and normalize to a unit vector
vChecker = reshape(pts3d,checkerSize(1),checkerSize(2),checkerSize(3));
vChecker = vChecker(rows,cols,:);
vChecker = reshape(vChecker,[],3);
vFit = (vChecker-meanVal)*rotmat'+shiftVec;

pts1 = [vResult(:,1)./vResult(:,3), vResult(:,2)./vResult(:,3)]';
pts2 = [vFit(:,1)./vFit(:,3), vFit(:,2)./vFit(:,3)]';
end