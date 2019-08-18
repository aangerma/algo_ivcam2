function [dfzRegs,results,calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs)
    % function [dfzRegs,results,calibPassed] = DFZ_Calib_Calc(InputPath,calibParams,DFZ_regs,regs_reff)
    % description: initiale set of the DSM scale and offset
    %regs_reff
    % inputs:
    %   InputPath -  path for input images  dir stucture InputPath\PoseN N =1:5
    %        note
    %           I image naming I_*_000n.bin
    %   calibParams - calibparams strcture.
    %   DFZ_regs - list of hw regs values and FW regs
    %
    % output:
    %   dfzRegs - frmw register (fov , polyvars, projectionYshear, laserangleH/V
    %   results - geomErr:  and extraImagesGeomErr:
    %   calibPassed - pass fail
    %
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_calib_dir g_LogFn; % g_regs g_luts;
    % setting default global value in case not initial in the init function;
    if isempty(g_debug_log_f)
        g_debug_log_f = 0;
    end
    if isempty(g_verbose)
        g_verbose = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_dummy_output_flag)
        g_dummy_output_flag = 0;
    end
    
    func_name = dbstack;
    func_name = func_name(1).name;
    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir, func_name,'temp');
    else
        output_dir = g_output_dir;
    end
    
    if(~isempty(g_calib_dir))
        calib_dir = g_calib_dir;
    else
        warning('calib_dir missing in cal_init');
    end
    
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end
    
    % save Input
    regs = ConvertDFZReg(DFZ_regs);
    if g_save_input_flag && exist(output_dir,'dir')~=0
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'InputPath', 'regs' , 'DFZ_regs' , 'calibParams');
    end
    [dfzRegs,calibPassed ,results] = DFZ_Calib_Calc_int(InputPath, calib_dir, output_dir, calibParams, fprintff, regs);       
    if ~isfield(results,'rtdDiffBetweenPresets')
            results.rtdDiffBetweenPresets = 0;
    end
    if ~isfield(results,'shortRangeImagesGeomErr')
            results.shortRangeImagesGeomErr = 0;
    end
    dfzRegs.FRMW.dfzCalTmp          = DFZ_regs.FRMWdfzCalTmp;
    dfzRegs.FRMW.dfzApdCalTmp       = DFZ_regs.FRMWdfzApdCalTmp;
    dfzRegs.FRMW.dfzVbias           = DFZ_regs.FRMWdfzVbias;
    dfzRegs.FRMW.dfzIbias           = DFZ_regs.FRMWdfzIbias;
    dfzRegs.FRMW.fovexExistenceFlag = regs.FRMW.fovexExistenceFlag;
    dfzRegs.FRMW.fovexLensDistFlag = regs.FRMW.fovexLensDistFlag;
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'dfzRegs', 'calibPassed','results');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

function [dfzRegs,calibPassed,results] = DFZ_Calib_Calc_int(InputPath, calib_dir, OutputDir, calibParams, fprintff, regs)
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
        outOfBoxIdxs = pts(:,:,1)< croppedBbox(1) | pts(:,:,1)>(croppedBbox(1)+croppedBbox(3)) | ...
            pts(:,:,2)<croppedBbox(2) | pts(:,:,2)>(croppedBbox(2)+croppedBbox(4));
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
    end
    runParams.outputFolder = OutputDir;
    Calibration.DFZ.saveDFZInputImage(d,runParams);
    % dodluts=struct;
    %% Collect stats  dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov
    
    if calibParams.dfz.performRegularDFZWithoutTPS
        
        doEval = 0;
        calibParams.dfz.calibrateOnCropped = 0;
        [dfzRegs,res,allVertices] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,doEval,[],runParams);
        results.geomErr = res.geomErr;        
        tpsUndistModel_vFullFromEval = [];
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

        end
         fprintff('eGeom Cropped: %.2g, eGeom Full: %.2g, eGeomFull(DFZ): %.2g, eGeom Full After TPS: %.2g, eGeom Full After TPS and delay optimization: %.2g\n',...
            resultsOnCropped.geomErr,resultsEvalOnFullAfterDfzWithCropped.geomErr,resultsOnFull.geomErr,resultsDFZcroppedDfzFullTps.geomErr,resultsDFZcroppedDfzFullTpsDfz.geomErr);



        results.geomErr = resultsDFZcroppedDfzFullTpsDfz.geomErr;
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