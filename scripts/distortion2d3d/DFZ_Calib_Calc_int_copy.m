function [dfzRegs,calibPassed,results] = DFZ_Calib_Calc_int_copy(InputPath, calib_dir, OutputDir, calibParams, fprintff, regs)
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
    im_IR = Calibration.aux.GetFramesFromDir(path,width, hight);
    IR_image = Calibration.aux.average_images(im_IR(:,:,(1:10)));
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
    im = GetDFZImages(nof_secne,InputPath,width,hight);
    
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
        
        [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(d(i).i, 1,0,0.2, 1);
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
    
    %% patch for eval ROI
    for iEvalRoi = 1:length(calibParams.dfz.cropRatiosForEval)
        croppedBoxesForEval = CropBoxesForEval(bbox, calibParams.dfz.cropRatiosForEval{iEvalRoi});
        dForEval{iEvalRoi} = CropDarrForEval(d, nof_secne, pts, croppedBoxesForEval, colors);
    end
    %%
    
    %runParams.outputFolder = OutputDir;
    runParams = [];
    Calibration.DFZ.saveDFZInputImage(d,runParams);
    % dodluts=struct;
    %% Collect stats  dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov
    metricParams.target.squareSize = 30;
    metricParams.camera.K = calibParams.dfz.Kfor2dError;
    metricParams.gridSize = [20,28];
    if calibParams.dfz.performRegularDFZWithoutTPS
        
        doEval = 0;
        calibParams.dfz.calibrateOnCropped = 0;
        [dfzRegs,res,allVertices] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,[],runParams);
        results.geomErr = res.geomErr;        
        results.lineFit = Calibration.aux.calcLineDistortion(allVertices,calibParams.dfz.Kfor2dError);
        [results.planeFit, results.scaleErr] = CalcPlaneFitAndScaleError(metricParams, allVertices);
        tpsUndistModel_vFullFromEval = [];
        
        %% patch for eval ROI
        x0 = double([dfzRegs.FRMW.xfov(1), dfzRegs.FRMW.yfov(1), dfzRegs.DEST.txFRQpd(1), dfzRegs.FRMW.laserangleH, dfzRegs.FRMW.laserangleV,...
            dfzRegs.FRMW.polyVars, dfzRegs.FRMW.pitchFixFactor, dfzRegs.FRMW.undistAngHorz, dfzRegs.FRMW.undistAngVert,...
            dfzRegs.FRMW.fovexNominal, dfzRegs.FRMW.fovexRadialK, dfzRegs.FRMW.fovexTangentP, dfzRegs.FRMW.fovexCenter]);
        doEval = true;
        calibParams.dfz.calibrateOnCropped = 1;
        for iEvalRoi = 1:length(dForEval)
            [~,resForEval{iEvalRoi},allVerticesForEval{iEvalRoi}] = Calibration.aux.calibDFZ(dForEval{iEvalRoi}(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams,tpsUndistModel_vFullFromEval);
            results.geomErrForEval{iEvalRoi} = resForEval{iEvalRoi}.geomErr;
            results.lineFitForEval{iEvalRoi} = Calibration.aux.calcLineDistortion(allVerticesForEval{iEvalRoi},calibParams.dfz.Kfor2dError);
            [results.planeFitForEval{iEvalRoi}, results.scaleErrForEval{iEvalRoi}] = CalcPlaneFitAndScaleError(metricParams, allVerticesForEval{iEvalRoi});
        end
    else
        

        doEval = 0;
        calibParams.dfz.calibrateOnCropped = 1;
        [dfzRegs,resultsOnCropped,allVerticesCropped] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,[],runParams);
        x0 = double([dfzRegs.FRMW.xfov(1), dfzRegs.FRMW.yfov(1), dfzRegs.DEST.txFRQpd(1), dfzRegs.FRMW.laserangleH, dfzRegs.FRMW.laserangleV,...
                dfzRegs.FRMW.polyVars, dfzRegs.FRMW.pitchFixFactor, dfzRegs.FRMW.undistAngHorz, dfzRegs.FRMW.undistAngVert,...
                dfzRegs.FRMW.fovexNominal, dfzRegs.FRMW.fovexRadialK, dfzRegs.FRMW.fovexTangentP, dfzRegs.FRMW.fovexCenter]);        

        if calibParams.dfz.calibrateOnlyCropped
            doEval = true;
            calibParams.dfz.calibrateOnCropped = 0;
            [~,resultsEvalOnFullAfterDfzWithCropped,allVertices] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams);
            resultsOnFull = resultsEvalOnFullAfterDfzWithCropped;
        else
            doEval = true;
            calibParams.dfz.calibrateOnCropped = 0;
            [~,resultsEvalOnFullAfterDfzWithCropped,allVertices] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams);
            doEval = 0;
            calibParams.dfz.calibrateOnCropped = 0;
            [dfzRegs,resultsOnFull,allVertices] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams);

        end
        x0 = double([dfzRegs.FRMW.xfov(1), dfzRegs.FRMW.yfov(1), dfzRegs.DEST.txFRQpd(1), dfzRegs.FRMW.laserangleH, dfzRegs.FRMW.laserangleV,...
                dfzRegs.FRMW.polyVars, dfzRegs.FRMW.pitchFixFactor, dfzRegs.FRMW.undistAngHorz, dfzRegs.FRMW.undistAngVert,...
                dfzRegs.FRMW.fovexNominal, dfzRegs.FRMW.fovexRadialK, dfzRegs.FRMW.fovexTangentP, dfzRegs.FRMW.fovexCenter]);        

        calibParams.dfz.calibrateOnCropped = 1;
        doEval = 1;
        [~,~,allVerticesCropped] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams);


        rotmatAll = zeros(length(allVerticesCropped),3,3);
        shiftAll = zeros(length(allVerticesCropped),1,3);
        meanValAll = zeros(length(allVerticesCropped),1,3);
        pts1_vFullFromEval = cell(1,length(allVerticesCropped));
        pts2_vFullFromEval = cell(1,length(allVerticesCropped));
        for k = 1:length(allVerticesCropped)
            % Get rid off NaNs
            v = allVerticesCropped{1,k};
            notNans = ~isnan(v(:,1));
            v = v(notNans,:);
            vNoNanCropped = v;
            vCheckerCropped = d(i).pts3d;
            vCheckerCropped = vCheckerCropped(notNans,:);
            vCheckerCropped = reshape(vCheckerCropped,[],3);
            % Calculate rotation and shift of rigid fit for cropped points
            [~,~,rotmat,shiftVec, meanVal] = Calibration.aux.rigidFit(vNoNanCropped,vCheckerCropped);
            rotmatAll(k,:,:) = rotmat;
            shiftAll(k,:,:) = shiftVec;
            meanValAll(k,:,:) = meanVal;
            [pts1_vFullFromEval{k},pts2_vFullFromEval{k}] = Calibration.DFZ.createPtsForPtsModel(allVertices{1,k},d(k).pts3d,meanVal,rotmat,shiftVec,d(i).grid(1:2));

        end
        pts1_vFullFromEval = cell2mat(pts1_vFullFromEval);
        pts2_vFullFromEval = cell2mat(pts2_vFullFromEval);

        tpsUndistModel_vFullFromEval= Calibration.Undist.createTpsUndistModel(pts1_vFullFromEval,pts2_vFullFromEval,runParams);



        calibParams.dfz.fovxRange = [dfzRegs.FRMW.xfov(1),dfzRegs.FRMW.xfov(1)];
        calibParams.dfz.fovyRange = [dfzRegs.FRMW.yfov(1),dfzRegs.FRMW.yfov(1)];
        calibParams.dfz.fovexCenterRange = [dfzRegs.FRMW.fovexCenter;dfzRegs.FRMW.fovexCenter];
        calibParams.dfz.fovexTangentRange = [dfzRegs.FRMW.fovexTangentP;dfzRegs.FRMW.fovexTangentP];
        calibParams.dfz.fovexRadialRange = [dfzRegs.FRMW.fovexRadialK;dfzRegs.FRMW.fovexRadialK];
        calibParams.dfz.fovexNominalRange = [dfzRegs.FRMW.fovexNominal;dfzRegs.FRMW.fovexNominal];
        calibParams.dfz.undistVertRange = [dfzRegs.FRMW.undistAngVert;dfzRegs.FRMW.undistAngVert];
        calibParams.dfz.undistHorzRange = [dfzRegs.FRMW.undistAngHorz;dfzRegs.FRMW.undistAngHorz];
        calibParams.dfz.pitchFixFactorRange = [dfzRegs.FRMW.pitchFixFactor,dfzRegs.FRMW.pitchFixFactor];
        calibParams.dfz.polyVarRange = [dfzRegs.FRMW.polyVars;dfzRegs.FRMW.polyVars];
        calibParams.dfz.zenithxRange = [dfzRegs.FRMW.laserangleH,dfzRegs.FRMW.laserangleH];
        calibParams.dfz.zenithyRange = [dfzRegs.FRMW.laserangleV,dfzRegs.FRMW.laserangleV];


        doEval = true;
        calibParams.dfz.calibrateOnCropped = 0;
        [~,resultsDFZcroppedDfzFullTps,~] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams,tpsUndistModel_vFullFromEval);
        doEval = false;
        if calibParams.dfz.calibrateOnlyCropped
            calibParams.dfz.calibrateOnCropped = 1;
            [dfzRegs,resultsDFZcroppedDfzFullTpsDfz,allVerticesFinal] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams,tpsUndistModel_vFullFromEval);
            doEval = true;
            calibParams.dfz.calibrateOnCropped = 0;
             x0 = double([dfzRegs.FRMW.xfov(1), dfzRegs.FRMW.yfov(1), dfzRegs.DEST.txFRQpd(1), dfzRegs.FRMW.laserangleH, dfzRegs.FRMW.laserangleV,...
            dfzRegs.FRMW.polyVars, dfzRegs.FRMW.pitchFixFactor, dfzRegs.FRMW.undistAngHorz, dfzRegs.FRMW.undistAngVert,...
            dfzRegs.FRMW.fovexNominal, dfzRegs.FRMW.fovexRadialK, dfzRegs.FRMW.fovexTangentP, dfzRegs.FRMW.fovexCenter]);

            [~,resultsDFZcroppedDfzFullTpsDfz,allVerticesFinal] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams,tpsUndistModel_vFullFromEval);

        else
            calibParams.dfz.calibrateOnCropped = 0;
            [dfzRegs,resultsDFZcroppedDfzFullTpsDfz,allVerticesFinal] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams,tpsUndistModel_vFullFromEval);
            %% patch for eval ROI
            x0 = double([dfzRegs.FRMW.xfov(1), dfzRegs.FRMW.yfov(1), dfzRegs.DEST.txFRQpd(1), dfzRegs.FRMW.laserangleH, dfzRegs.FRMW.laserangleV,...
            dfzRegs.FRMW.polyVars, dfzRegs.FRMW.pitchFixFactor, dfzRegs.FRMW.undistAngHorz, dfzRegs.FRMW.undistAngVert,...
            dfzRegs.FRMW.fovexNominal, dfzRegs.FRMW.fovexRadialK, dfzRegs.FRMW.fovexTangentP, dfzRegs.FRMW.fovexCenter]);
            doEval = true;
            calibParams.dfz.calibrateOnCropped = 1;
            for iEvalRoi = 1:length(dForEval)
                [~,resultsDFZcroppedDfzFullTpsDfzForEval{iEvalRoi},allVerticesFinalForEval{iEvalRoi}] = Calibration.aux.calibDFZ(dForEval{iEvalRoi}(trainImages),regs,calibParams,fprintff,0,doEval,x0,runParams,tpsUndistModel_vFullFromEval);
            end
            %%

        end
         fprintff('eGeom Cropped: %.2g, eGeom Full: %.2g, eGeomFull(DFZ): %.2g, eGeom Full After TPS: %.2g, eGeom Full After TPS and delay optimization: %.2g\n',...
            resultsOnCropped.geomErr,resultsEvalOnFullAfterDfzWithCropped.geomErr,resultsOnFull.geomErr,resultsDFZcroppedDfzFullTps.geomErr,resultsDFZcroppedDfzFullTpsDfz.geomErr);

        results.geomErr = resultsDFZcroppedDfzFullTpsDfz.geomErr;
        results.lineFit = Calibration.aux.calcLineDistortion(allVerticesFinal,calibParams.dfz.Kfor2dError);
        [results.planeFit, results.scaleErr] = CalcPlaneFitAndScaleError(metricParams, allVerticesFinal);
        for iEvalRoi = 1:length(dForEval)
            results.geomErrForEval{iEvalRoi} = resultsDFZcroppedDfzFullTpsDfzForEval{iEvalRoi}.geomErr;
            results.lineFitForEval{iEvalRoi} = Calibration.aux.calcLineDistortion(allVerticesFinalForEval{iEvalRoi},calibParams.dfz.Kfor2dError);
            [results.planeFitForEval{iEvalRoi}, results.scaleErrForEval{iEvalRoi}] = CalcPlaneFitAndScaleError(metricParams, allVerticesFinalForEval{iEvalRoi});
        end
    end
    results.potentialPitchFixInDegrees = dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov(1)/4096;
    fprintff('Pitch factor fix in degrees = %.2g (At the left & right sides of the projection)\n',results.potentialPitchFixInDegrees);
%         [dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,[],[],runParams);
    
    x0 = double([dfzRegs.FRMW.xfov(1), dfzRegs.FRMW.yfov(1), dfzRegs.DEST.txFRQpd(1), dfzRegs.FRMW.laserangleH, dfzRegs.FRMW.laserangleV,...
        dfzRegs.FRMW.polyVars, dfzRegs.FRMW.pitchFixFactor, dfzRegs.FRMW.undistAngHorz, dfzRegs.FRMW.undistAngVert,...
        dfzRegs.FRMW.fovexNominal, dfzRegs.FRMW.fovexRadialK, dfzRegs.FRMW.fovexTangentP, dfzRegs.FRMW.fovexCenter]);
    
    if ~isempty(d(testImages))
        [~,dfzResults] = Calibration.aux.calibDFZ(d(testImages),regs,calibParams,fprintff,0,1,x0,runParams,tpsUndistModel_vFullFromEval);
        results.extraImagesGeomErr = dfzResults.geomErr;
        fprintff('geom error on test set =%.2g\n',results.extraImagesGeomErr);
    else
        results.extraImagesGeomErr = 0;
        fprintff('No test set.\n');
    end
    
    if ~isempty(d(shortRangeImages)) && sum(shortRangeImages) == 1
        srInd = find(shortRangeImages,1,'first');
        lrInd = srInd-1;
        if nanmean(vec(abs((d(srInd).pts(:,:,1)-d(lrInd).pts(:,:,1))))) > 1 % If average corner location is bigger than 1 pixel we probably have missmatched captures
            fprintff('Long and short range presets DFZ captures are not of the same scene! Short range preset calib failed \n')
            calibPassed = 0;
    
        end
        invalidCBPoints = isnan(d(lrInd).rpt(:,1).*d(srInd).rpt(:,1));
        d(lrInd).rpt = d(lrInd).rpt.*(~invalidCBPoints);
        d(lrInd).rpt(invalidCBPoints,:) = nan;
        d(srInd).rpt = d(srInd).rpt.*(~invalidCBPoints);
        d(srInd).rpt(invalidCBPoints,:) = nan;
        d(lrInd).pts = d(lrInd).pts.*reshape(~invalidCBPoints,d(lrInd).grid);
        d(lrInd).pts(invalidCBPoints,:) = nan;
        d(srInd).pts = d(srInd).pts.*reshape(~invalidCBPoints,d(srInd).grid);
        d(srInd).pts(invalidCBPoints,:) = nan;
        
        params = Validation.aux.defaultMetricsParams();
        params.roi = calibParams.dfz.shortRangeCompareROI ; params.isRoiRect=1; 
        mask = Validation.aux.getRoiMask(size(d(lrInd).i), params);
        results.rtdDiffBetweenPresets = mean(d(lrInd).z(mask)/4*2) - mean(d(srInd).z(mask)/4*2);
%         
%         results.rtdDiffBetweenPresets = nanmean( d(lrInd).rpt(:,1) - d(srInd).rpt(:,1) );
        d(srInd).rpt(:,1) = d(srInd).rpt(:,1) + results.rtdDiffBetweenPresets;
        [~,dfzResults] = Calibration.aux.calibDFZ(d(srInd),regs,calibParams,fprintff,0,1,x0,runParams,tpsUndistModel_vFullFromEval);
        results.shortRangeImagesGeomErr = dfzResults.geomErr;
        fprintff('geom error on short range image =%.2g\n',results.shortRangeImagesGeomErr);
        fprintff('Rtd diff between presets =%.2g\n',results.rtdDiffBetweenPresets);
        
        % Write results to CSV and burn 2 device
%        shortRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','shortRangePreset.csv');
%         shortRangePresetFn = fullfile(calib_dir,'shortRangePreset.csv');
%         shortRangePreset=readtable(shortRangePresetFn);
%         modRefInd=find(strcmp(shortRangePreset.name,'AlgoThermalLoopOffset')); 
%         shortRangePreset.value(modRefInd) = results.rtdDiffBetweenPresets;
%         writetable(shortRangePreset,shortRangePresetFn);
    end
    
    
    if(results.geomErr<calibParams.errRange.geomErr(2))
        fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
        calibPassed = 1;
    else
        fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
    end
end

function [im] = GetDFZImages(nof_secne,InputPath,width,hight)
    dirfiles = dir([InputPath,'\Pose*']);
    for i=1:nof_secne
        im(i).i = Calibration.aux.GetFramesFromDir(fullfile(InputPath,dirfiles(i).name),width, hight);
        im(i).z = Calibration.aux.GetFramesFromDir(fullfile(InputPath,dirfiles(i).name),width, hight,'Z');
        im(i).i = Calibration.aux.average_images(im(i).i);
        im(i).z = Calibration.aux.average_images(im(i).z);
    end
    global g_output_dir g_save_input_flag;
    if g_save_input_flag % save
        fn = fullfile(g_output_dir, 'mat_files' , 'DFZ_im.mat');
        save(fn,'im');
    end
end

function  DFZRegs = ConvertDFZReg(regs)
    DFZRegs.DEST.depthAsRange   	= logical(regs.DESTdepthAsRange);
    DFZRegs.DIGG.sphericalEn    	= logical(regs.DIGGsphericalEn);
    %    DFZRegs.DIGG.sphericalScale 	= typecast(regs.DIGGsphericalScale,'int16');
    temp = typecast(regs.DESTbaseline,'single');
    DFZRegs.DEST.baseline   		= temp(1); %typecast(regs.DESTbaseline,'single');
    DFZRegs.DEST.baseline2			= temp(2); %typecast(regs.DESTbaseline2,'single');
    DFZRegs.GNRL.zMaxSubMMExp       = uint16(regs.GNRLzMaxSubMMExp);
    DFZRegs.DEST.p2axa 				= typecast(regs.DESTp2axa,'single');
    DFZRegs.DEST.p2axb 				= typecast(regs.DESTp2axb,'single');
    DFZRegs.DEST.p2aya 				= typecast(regs.DESTp2aya,'single');
    DFZRegs.DEST.p2ayb 				= typecast(regs.DESTp2ayb,'single');
    DFZRegs.DIGG.sphericalOffset	= typecast(bitand(regs.DIGGsphericalOffset,hex2dec('0fffffff')),'int16');
    DFZRegs.DIGG.sphericalScale 	= typecast(bitand(regs.DIGGsphericalScale ,hex2dec('0fff0fff')),'int16');
    DFZRegs.DEST.hbaseline          = logical(regs.DESThbaseline);
    DFZRegs.DEST.txFRQpd            = typecast(regs.DESTtxFRQpd,'single')'; %x3
    DFZRegs.GNRL.imgHsize           = uint16(regs.GNRLimgHsize);
    DFZRegs.GNRL.imgVsize           = uint16(regs.GNRLimgVsize);
    
    DFZRegs.FRMW.mirrorMovmentMode  = regs.FRMWmirrorMovmentMode;
    DFZRegs.FRMW.xfov 				= regs.FRMWxfov;
    DFZRegs.FRMW.yfov 				= regs.FRMWyfov;
    DFZRegs.FRMW.projectionYshear 	= regs.FRMWprojectionYshear;
    DFZRegs.FRMW.laserangleH       	= regs.FRMWlaserangleH;
    DFZRegs.FRMW.laserangleV 		= regs.FRMWlaserangleV;
    DFZRegs.FRMW.guardBandH         = regs.FRMWguardBandH;
    DFZRegs.FRMW.guardBandV 		= regs.FRMWguardBandV;
    DFZRegs.FRMW.xres 				= regs.FRMWxres;
    DFZRegs.FRMW.yres 				= regs.FRMWyres;
    DFZRegs.FRMW.polyVars 			= regs.FRMWpolyVars; % x3
    DFZRegs.FRMW.marginL            = regs.FRMWmarginL;
    DFZRegs.FRMW.marginR            = regs.FRMWmarginR;
    DFZRegs.FRMW.marginT            = regs.FRMWmarginT;
    DFZRegs.FRMW.marginB            = regs.FRMWmarginB;
    DFZRegs.FRMW.yflip              = regs.FRMWyflip;
    DFZRegs.FRMW.xR2L               = regs.FRMWxR2L; 
    DFZRegs.FRMW.pitchFixFactor     = regs.FRMWpitchFixFactor;              % logical (bool) (0)
   
    DFZRegs.FRMW.undistAngHorz      = regs.FRMWundistAngHorz;
    DFZRegs.FRMW.undistAngVert      = regs.FRMWundistAngVert;
    DFZRegs.FRMW.fovexExistenceFlag = regs.FRMWfovexExistenceFlag;
    DFZRegs.FRMW.fovexNominal       = regs.FRMWfovexNominal;
    DFZRegs.FRMW.fovexLensDistFlag  = regs.FRMWfovexLensDistFlag;
    DFZRegs.FRMW.fovexRadialK       = regs.FRMWfovexRadialK;
    DFZRegs.FRMW.fovexTangentP      = regs.FRMWfovexTangentP;
    DFZRegs.FRMW.fovexCenter        = regs.FRMWfovexCenter;

    % update list
%     DFZRegs.FRMW.dfzCalTmp          = regs.FRMWdfzCalTmp;
%     DFZRegs.FRMW.dfzApdCalTmp       = regs.FRMWdfzApdCalTmp;
%     DFZRegs.FRMW.dfzVbias           = regs.FRMWdfzVbias;
%     DFZRegs.FRMW.dfzIbias           = regs.FRMWdfzIbias;


    DFZRegs.MTLB.fastApprox(1)          	= logical(regs.MTLBfastApprox(1));
end

function croppedBoxesForEval = CropBoxesForEval(bbox, cropRatiosForEval)
    croppedBoxesForEval = zeros(size(cropRatiosForEval,1),4);
    for cropR = 1:size(cropRatiosForEval,1)
        cropRatioX = cropRatiosForEval(cropR,1);
        cropRatioY = cropRatiosForEval(cropR,2);

        croppedBbox = bbox;
        croppedBbox(1) = croppedBbox(1) + cropRatioX*croppedBbox(3);
        croppedBbox(3) = (1-2*cropRatioX)*croppedBbox(3);
        croppedBbox(2) = croppedBbox(2) + cropRatioY*croppedBbox(4);
        croppedBbox(4) = (1-2*cropRatioY)*croppedBbox(4);
        
        croppedBoxesForEval(cropR,:) = croppedBbox;
    end
end

function dForEval = CropDarrForEval(d, nof_secne, pts, croppedBoxesForEval, colors)
    dForEval = d;
    for i = 1:nof_secne
        outOfBoxIdxsForEval = ones(size(pts(:,:,1)));
        for cropR = 1:size(croppedBoxesForEval,1)
            outOfCurrBoxIdxs = pts(:,:,1)< croppedBoxesForEval(cropR,1) | pts(:,:,1)>(croppedBoxesForEval(cropR,1)+croppedBoxesForEval(cropR,3)) | ...
                           pts(:,:,2)<croppedBoxesForEval(cropR,2) | pts(:,:,2)>(croppedBoxesForEval(cropR,2)+croppedBoxesForEval(cropR,4)); 
            outOfBoxIdxsForEval = outOfBoxIdxsForEval & outOfCurrBoxIdxs;
        end
        
        ptsCropped1 = dForEval(i).pts(:,:,1);
        ptsCropped2 = dForEval(i).pts(:,:,2);
        ptsCropped1(outOfBoxIdxsForEval)= NaN;
        ptsCropped2(outOfBoxIdxsForEval)= NaN;
        ptsCropped = cat(3,ptsCropped1,ptsCropped2);
        colorsCropped = colors;
        colorsCropped(outOfBoxIdxsForEval)= NaN;
        rptCropped = dForEval(i).rpt;
        rptCropped(outOfBoxIdxsForEval(:),:) = NaN; 
       
        dForEval(i).ptsCropped = ptsCropped;
        dForEval(i).colorsCropped = colorsCropped;
        dForEval(i).gridCropped = dForEval(i).grid;
        dForEval(i).rptCropped = rptCropped;
    end
end

function [resultsPlaneFitForEval, resultsScaleErrForEval] = CalcPlaneFitAndScaleError(metricParams, allVerticesFinalForEval)
    n = length(allVerticesFinalForEval);
    for iIm = 1:n
        [~, planeFitForEval{iIm}, ~] = Validation.metrics.planeFitOnCorners([], metricParams, allVerticesFinalForEval{iIm});
        [~, scaleErrForEval{iIm}, ~] = Validation.metrics.gridInterDist([], metricParams, allVerticesFinalForEval{iIm});
    end
    resultsPlaneFitForEval.rmsPlaneFitDist = nanmean(cellfun(@(x) x.rmsPlaneFitDist, planeFitForEval));
    resultsPlaneFitForEval.maxPlaneFitDist = nanmean(cellfun(@(x) x.maxPlaneFitDist, planeFitForEval));
    resultsScaleErrForEval.meanHorzScaleError = nanmean(cellfun(@(x) x.meanHorzScaleError, scaleErrForEval));
    resultsScaleErrForEval.meanAbsHorzScaleError = nanmean(cellfun(@(x) x.meanAbsHorzScaleError, scaleErrForEval));
    resultsScaleErrForEval.meanVertScaleError = nanmean(cellfun(@(x) x.meanVertScaleError, scaleErrForEval));
    resultsScaleErrForEval.meanAbsVertScaleError = nanmean(cellfun(@(x) x.meanAbsVertScaleError, scaleErrForEval));
end
