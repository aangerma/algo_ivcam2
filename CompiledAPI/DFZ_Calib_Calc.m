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
function opt = defaultDfzOptions()
    opt.iseval = 0;
    opt.verbose = 0;
    opt.useCropped = 0;
    opt.optimizedParamsStr = '';
end
function [dfzRegs,calibPassed,results] = DFZ_Calib_Calc_int(InputPath, calib_dir, OutputDir, calibParams, fprintff, regs)
    calibPassed = 0;
    captures = {calibParams.dfz.captures.capture(:).type};
    shortRangeImages = strcmp('shortRange',captures);
    trainImages = strcmp('train',captures);
    testImages = strcmp('test',captures);
    runParams.outputFolder = OutputDir;
    framesData = prepareDataForOptimization(InputPath, calib_dir, OutputDir, calibParams, fprintff, regs);
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

    if calibParams.dfz.performRegularDFZWithoutTPS
        [dfzRegs,res,allVertices] = optDfzOnFull(framesData(trainImages),[],xbest,runParams);
        results.geomErr = res.geomErr;
    else

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
    end
    
    
    

    results.potentialPitchFixInDegrees = dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov(1)/4096;
    fprintff('Pitch factor fix in degrees = %.2g (At the left & right sides of the projection)\n',results.potentialPitchFixInDegrees);
%         [dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,[],[],runParams);
    
    if ~isempty(framesData(testImages))
        [~,dfzResults] = evalDfzOnFull(framesData(testImages),tpsUndistModel,xbest,runParams);
        results.extraImagesGeomErr = dfzResults.geomErr;
        fprintff('geom error on test set =%.2g\n',results.extraImagesGeomErr);
    else
        results.extraImagesGeomErr = 0;
        fprintff('No test set.\n');
    end
    
    if ~isempty(framesData(shortRangeImages)) && sum(shortRangeImages) == 1
        srInd = find(shortRangeImages,1,'first');
        lrInd = srInd-1;
        if nanmean(vec(abs((framesData(srInd).pts(:,:,1)-framesData(lrInd).pts(:,:,1))))) > 1 % If average corner location is bigger than 1 pixel we probably have missmatched captures
            fprintff('Long and short range presets DFZ captures are not of the same scene! Short range preset calib failed \n')
            calibPassed = 0;
    
        end
        invalidCBPoints = isnan(framesData(lrInd).rpt(:,1).*framesData(srInd).rpt(:,1));
        framesData(lrInd).rpt = framesData(lrInd).rpt.*(~invalidCBPoints);
        framesData(lrInd).rpt(invalidCBPoints,:) = nan;
        framesData(srInd).rpt = framesData(srInd).rpt.*(~invalidCBPoints);
        framesData(srInd).rpt(invalidCBPoints,:) = nan;
        framesData(lrInd).pts = framesData(lrInd).pts.*reshape(~invalidCBPoints,framesData(lrInd).grid);
        framesData(lrInd).pts(invalidCBPoints,:) = nan;
        framesData(srInd).pts = framesData(srInd).pts.*reshape(~invalidCBPoints,framesData(srInd).grid);
        framesData(srInd).pts(invalidCBPoints,:) = nan;
        
        params = Validation.aux.defaultMetricsParams();
        params.roi = calibParams.dfz.shortRangeCompareROI ; params.isRoiRect=1; 
        mask = Validation.aux.getRoiMask(size(framesData(lrInd).i), params);
        results.rtdDiffBetweenPresets = mean(framesData(lrInd).z(mask)/4*2) - mean(framesData(srInd).z(mask)/4*2);
%         
%         results.rtdDiffBetweenPresets = nanmean( framesData(lrInd).rpt(:,1) - framesData(srInd).rpt(:,1) );
        framesData(srInd).rpt(:,1) = framesData(srInd).rpt(:,1) + results.rtdDiffBetweenPresets;
        framesData(srInd).rptCropped(:,1) = framesData(srInd).rptCropped(:,1) + results.rtdDiffBetweenPresets;

%         [~,dfzResults] = Calibration.aux.calibDFZ(framesData(srInd),regs,calibParams,fprintff,0,1,xbest,runParams,tpsUndistModel);
        [~,dfzResults] = evalDfzOnCropped(framesData(srInd),tpsUndistModel,xbest,[]);
        results.shortRangeImagesGeomErr = dfzResults.geomErr;
        fprintff('geom error on short range image =%.2g\n',results.shortRangeImagesGeomErr);
        fprintff('Rtd diff between presets =%.2g\n',results.rtdDiffBetweenPresets);
        
        % Write results to CSV and burn 2 device
%        shortRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','shortRangePreset.csv');
%         shortRangePresetFn = fullfile(calib_dir,'shortRangePreset.csv');
%         shortRangePreset=readtable(shortRangePresetFn);
%         modRefInd=finframesData(strcmp(shortRangePreset.name,'AlgoThermalLoopOffset')); 
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
    DFZRegs.FRMW.rtdOverY           = regs.FRMWrtdOverY;
    DFZRegs.FRMW.saTiltFromEs       = regs.FRMWsaTiltFromEs;
    DFZRegs.FRMW.faTiltFromEs       = regs.FRMWfaTiltFromEs;
        
    % update list
%     DFZRegs.FRMW.dfzCalTmp          = regs.FRMWdfzCalTmp;
%     DFZRegs.FRMW.dfzApdCalTmp       = regs.FRMWdfzApdCalTmp;
%     DFZRegs.FRMW.dfzVbias           = regs.FRMWdfzVbias;
%     DFZRegs.FRMW.dfzIbias           = regs.FRMWdfzIbias;


    DFZRegs.MTLB.fastApprox(1)          	= logical(regs.MTLBfastApprox(1));
end
function d = prepareDataForOptimization(InputPath, calib_dir, OutputDir, calibParams, fprintff, regs)
    % Prepare the strcut array d. With has the corners data for each CB
    % point
    captures = {calibParams.dfz.captures.capture(:).type};
    
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
    runParams.outputFolder = OutputDir;
    Calibration.DFZ.saveDFZInputImage(d,runParams);
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
