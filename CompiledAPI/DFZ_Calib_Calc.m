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
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff; % g_regs g_luts;
    fprintff = g_fprintff;
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
        output_dir = fullfile(tempdir, func_name,'temp');
    else
        output_dir = g_output_dir;
    end
    
    if(isempty(fprintff))
        fprintff = @(varargin) fprintf(varargin{:});
    end

    % save Input
    regs = ConvertDFZReg(DFZ_regs);
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, [func_name '_in.mat']);
        save(fn,'InputPath', 'regs' , 'DFZ_regs' , 'calibParams');
    end
    [dfzRegs,calibPassed ,results] = DFZ_Calib_Calc_int(InputPath, output_dir, calibParams, fprintff, regs);       

    dfzRegs.FRMW.dfzCalTmp          = DFZ_regs.FRMWdfzCalTmp;
    dfzRegs.FRMW.dfzApdCalTmp       = DFZ_regs.FRMWdfzApdCalTmp;
    dfzRegs.FRMW.dfzVbias           = DFZ_regs.FRMWdfzVbias;
    dfzRegs.FRMW.dfzIbias           = DFZ_regs.FRMWdfzIbias;

    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, [func_name '_out.mat']);
        save(fn,'dfzRegs', 'calibPassed','results');
    end

end

function [dfzRegs,calibPassed,results] = DFZ_Calib_Calc_int(InputPath, OutputDir, calibParams, fprintff, regs)
    calibPassed = 0;
    captures = {calibParams.dfz.captures.capture(:).type};
    trainImages = strcmp('train',captures);
    testImages = ~trainImages;

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

%{  
    % remove later for debug bit exect against org DFZ
    
%        a = load('C:\temp\unitCalib\F8200120\PC106\org_DFZ_im.mat');
%        a = load('C:\temp\unitCalib\F9090305\PC42\DFZ_im.mat');
        a = load('C:\temp\unitCalib\F9090305\PC62\im_org.mat');
        b = a.im;
        im = b;
    end
%}    
    for i = 1:nof_secne
        cap = calibParams.dfz.captures.capture(i);
        targetInfo = targetInfoGenerator(cap.target);

%}
%{        
   for i = 1:numel(captures)
        cap = calibParams.dfz.captures.capture(i);
        targetInfo = targetInfoGenerator(cap.target);
        targetInfo.cornersX = 20;
        targetInfo.cornersY = 28;
        i_path = fullfile(InputPath,sprintf('%d',i),'I');
        z_path = fullfile(InputPath,sprintf('%d',i),'Z');
        im(i).i = Calibration.dataDelay.GetFramesFromDir(i_path,width, hight);
        im(i).z = Calibration.dataDelay.GetFramesFromDir(z_path,width, hight);
        im(i).i = Calibration.dataDelay.average_images(im(i).i);
        im(i).z = Calibration.dataDelay.average_images(im(i).z);
 %}
        d(i).i = im(i).i;
        d(i).z = im(i).z;
      
        pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(d(i).i, 1);
        grid = [size(pts,1),size(pts,2),1];            
%       [pts,grid] = Validation.aux.findCheckerboard(im(i).i,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
%        grid(end+1) = 1;
        targetInfo.cornersX = grid(1);
        targetInfo.cornersY = grid(2);

        
%        d(i).c = im(i).c;
        d(i).pts = pts;
        d(i).grid = grid;
        d(i).pts3d = create3DCorners(targetInfo)';
        d(i).rpt = Calibration.aux.samplePointsRtd(im(i).z,pts,regs);


        croppedBbox = bbox;
        cropRatioX = 0.2;
        cropRatioY = 0.1;
        croppedBbox(1) = croppedBbox(1) + cropRatioX*croppedBbox(3);
        croppedBbox(3) = (1-2*cropRatioX)*croppedBbox(3);
        croppedBbox(2) = croppedBbox(2) + cropRatioY*croppedBbox(4);
        croppedBbox(4) = (1-2*cropRatioY)*croppedBbox(4);
        croppedBbox = int32(croppedBbox);
        imCropped = zeros(size(im(i).i));
        imCropped(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3)) = ...
            im(i).i(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3));
%             [ptsCropped, gridCropped] = detectCheckerboard(imCropped);
        ptsCropped = Calibration.aux.CBTools.findCheckerboardFullMatrix(imCropped, 1);
        gridCropped = [size(ptsCropped,1),size(ptsCropped,2),1];
%       [ptsCropped,gridCropped] = Validation.aux.findCheckerboard(imCropped,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
        gridCropped(end+1) = 1;

        d(i).ptsCropped = ptsCropped;
        d(i).gridCropped = gridCropped;
        d(i).rptCropped = Calibration.aux.samplePointsRtd(im(i).z,ptsCropped,regs);
    end
    runParams.outputFolder = OutputDir;
    Calibration.DFZ.saveDFZInputImage(d,runParams);
    % dodluts=struct;
    %% Collect stats  dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov
    [dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,[],[],runParams);
%         calibParams.dfz.pitchFixFactorRange = [0,0];
    results.potentialPitchFixInDegrees = dfzRegs.FRMW.pitchFixFactor*dfzRegs.FRMW.yfov(1)/4096;
    fprintff('Pitch factor fix in degrees = %.2g (At the left & right sides of the projection)\n',results.potentialPitchFixInDegrees);
%         [dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(trainImages),regs,calibParams,fprintff,0,[],[],runParams);
    
    x0 = double([dfzRegs.FRMW.xfov(1) dfzRegs.FRMW.yfov(1) dfzRegs.DEST.txFRQpd(1) dfzRegs.FRMW.laserangleH dfzRegs.FRMW.laserangleV dfzRegs.FRMW.polyVars dfzRegs.FRMW.pitchFixFactor]); 

    if ~isempty(d(testImages))
        [~,results.extraImagesGeomErr] = Calibration.aux.calibDFZ(d(testImages),regs,calibParams,fprintff,0,1,x0,runParams);
        fprintff('geom error on test set =%.2g\n',results.extraImagesGeomErr);
    end
    if(results.geomErr<calibParams.errRange.geomErr(2))
        fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
        calibPassed = 1;
    else
        fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
    end
end

function [im] = GetDFZImages(nof_secne,InputPath,width,hight)
    for i=1:nof_secne
%        i_path = fullfile(InputPath,sprintf('%d',i),'I');
%        z_path = fullfile(InputPath,sprintf('%d',i),'Z');
        path = fullfile(InputPath,sprintf('Pose%d',i));
        im(i).i = Calibration.aux.GetFramesFromDir(path,width, hight);
        im(i).z = Calibration.aux.GetFramesFromDir(path,width, hight,'Z');
        im(i).i = Calibration.aux.average_images(im(i).i);
        im(i).z = Calibration.aux.average_images(im(i).z);
    end
    global g_output_dir g_save_input_flag; 
    if g_save_input_flag % save 
            fn = fullfile(g_output_dir, 'DFZ_im.mat');
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
    DFZRegs.DIGG.sphericalOffset	= typecast(bitand(regs.DIGGsphericalOffset,hex2dec('00ff0fff')),'int16');
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
   
    % update list
%     DFZRegs.FRMW.dfzCalTmp          = regs.FRMWdfzCalTmp;
%     DFZRegs.FRMW.dfzApdCalTmp       = regs.FRMWdfzApdCalTmp;
%     DFZRegs.FRMW.dfzVbias           = regs.FRMWdfzVbias;
%     DFZRegs.FRMW.dfzIbias           = regs.FRMWdfzIbias;


    DFZRegs.MTLB.fastApprox(1)          	= logical(regs.MTLBfastApprox(1));
end