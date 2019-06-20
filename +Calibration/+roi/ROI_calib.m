function [results,roiRegs] = ROI_calib(hw,dfzRegs, runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Calibrating ROI... \n');
    if (runParams.ROI)
        [r,regs] = ROI_calib_Init(hw,fw);
        %% capture frames
        fprintff('[-] Collecting up/down frames... ');
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'ROI - Make sure image is bright',1);
        %% capture up down frames 
        gainCalibValue = '000ffff0';
        NumberOfFrames = 30;
        [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
        Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
        InputPath = fullfile(tempdir,'ROI'); 
        path_up = fullfile(InputPath,'IR_up');
        Calibration.aux.SaveFramesWrapper(hw , 'I' , NumberOfFrames, path_up);             % get frame without post processing (averege) (SDK like)

        Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
        path_down = fullfile(InputPath,'IR_down');
        Calibration.aux.SaveFramesWrapper(hw, 'I' , NumberOfFrames, path_down);             % get frame without post processing (averege) (SDK like)
        Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values
        pause(0.1);
        fprintff('Done.\n');
        % Remove modulation as well to get a noise image
        %% capture noise frames
        collectNoiseIm(hw,InputPath);
        %% prepare register set for ROI
        [ROIregs] = prepare_ROI_reg(hw,regs,dfzRegs);
        %% ROI algo    
        [roiRegs,results,fovData] = ROI_Calib_Calc(InputPath, calibParams, ROIregs,results);
        %% ROI post
        r.reset();
        %% for matlab tool 
        % Ambient value - Mean of the center 21x21 (arbitrary) patch in the noise image.
%{
%%        will moved to after undist calc
        fw.setRegs(roiRegs, fnCalib);
        fw.get(); % run bootcalcs
        fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoROICalib.txt');
        fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
        hw.runScript(fnAlgoTmpMWD);
        hw.shadowUpdate();
%}
        fprintff('[v] Done(%ds)\n',round(toc(t)));
        results.upDownFovDiff = sum(abs(fovData.laser.minMaxAngYup-fovData.laser.minMaxAngYdown));
        fprintff('Mirror opening angles slow and fast:      [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngX);
        fprintff('                                          [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngY);
        fprintff('Laser opening angles slow (up):           [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXup);
        fprintff('Laser opening angles slow (down):         [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXdown);
        fprintff('Laser opening angles fast (up):           [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYup);
        fprintff('Laser opening angles fast (down):         [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYdown);
        fprintff('Laser up/down fov diff:  %2.3g degrees.\n',results.upDownFovDiff);
    else
        roiRegs = struct;
        fprintff('[?] skipped\n');
    end
end

function [roiRegs,results,fovData] = ROI_Calib_Calc_ddd(InputPath, calibParams, ROI_regs,runParams)
    width = calibParams.gnrl.externalImSize(2);
    hight = calibParams.gnrl.externalImSize(1);
    [imUbias,imDbias,imNoise] = GetROIImages(InputPath,width,hight);
     results.ambVal = mean(vec(imNoise(size(imNoise,1)/2-10:size(imNoise,1)/2+10, size(imNoise,2)/2-10:size(imNoise,2)/2+10)));
    [roiRegs] = Calibration.roi.calibROI(imUbias,imDbias,imNoise,ROI_regs,calibParams,runParams);
    FE = [];
    if calibParams.fovExpander.valid
        FE = calibParams.fovExpander.table;
    end
    fovData = Calibration.validation.calculateFOV(imUbias,imDbias,imNoise,ROI_regs,FE);

end

function [r,regs] = ROI_calib_Init(hw,fw)
    regs = fw.get(); % run bootcalcs
%% Get spherical of both directions:
    r = Calibration.RegState(hw);
    r.add('DIGGsphericalEn'    ,true     );
    r.set();
end


% internal vunction
function [] = collectNoiseIm(hw,path)
    hw.cmd('iwb e2 06 01 00'); % Remove bias
    hw.cmd('iwb e2 08 01 0');  % modulation amp is 0
    hw.cmd('iwb e2 03 01 10'); % internal modulation (from register)
    pause(0.3);
    path = fullfile(path,'IR_Noise');
    Calibration.aux.SaveFramesWrapper(hw , 'I' , 10, path);             % get frame without post processing (averege) (SDK like)
    hw.cmd('iwb e2 03 01 90'); % 
    hw.cmd('iwb e2 06 01 70'); % Return bias
end


function [imUbias,imDbias,imNoise] = GetROIImages(InputPath,width,hight)
    path_up     = fullfile(InputPath,'IR_up');
    path_down   = fullfile(InputPath,'IR_down');
    path_noise  = fullfile(InputPath,'IR_Noise');
    imUbias = Calibration.aux.GetFramesFromDir(path_up,width, hight,'I');
    imDbias = Calibration.aux.GetFramesFromDir(path_down,width, hight,'I');
    imNoise = Calibration.aux.GetFramesFromDir(path_noise,width, hight,'I');
    imUbias = Calibration.aux.average_images(imUbias);
    imDbias = Calibration.aux.average_images(imDbias);
    imNoise = Calibration.aux.average_images(imNoise);
    imNoise = double(imNoise)/255;
    global g_output_dir g_save_input_flag; 
    if g_save_input_flag % save 
        fn = fullfile(g_output_dir, 'ROI_im.mat');
        save(fn,'imUbias', 'imDbias','imNoise');
    end
end

function [ROIregs] = prepare_ROI_reg(hw,regs,DFZ_regs)
        mode = regs.FRMW.mirrorMovmentMode;
if 1
        ROIregs.DIGGsphericalOffset         = hw.read('DIGGsphericalOffset');   %regs.DIGG.sphericalOffset;
        ROIregs.DIGGsphericalScale          = hw.read('DIGGsphericalScale');    %regs.DIGG.sphericalScale
        ROIregs.GNRLimgHsize                = hw.read('GNRLimgHsize');          %regs.GNRL.imgHsize;
        ROIregs.GNRLimgVsize                = hw.read('GNRLimgVsize');          %regs.GNRL.imgVsize;
        ROIregs.FRMWmirrorMovmentMode       = regs.FRMW.mirrorMovmentMode;      %uint16         (1)
        ROIregs.FRMWmarginB                 = regs.FRMW.marginB;                % int16          (0)
        ROIregs.FRMWmarginL                 = regs.FRMW.marginL;                % int16          (0)
        ROIregs.FRMWmarginR                 = regs.FRMW.marginR;                % int16          (0)
        ROIregs.FRMWmarginT                 = regs.FRMW.marginT;                % int16          (0)
        ROIregs.FRMWguardBandH              = regs.FRMW.guardBandH;             % single         (0)
        ROIregs.FRMWguardBandV              = regs.FRMW.guardBandV;             % single         (0)
        ROIregs.FRMWxfov(mode)              = DFZ_regs.FRMW.xfov(mode);         % single         
        ROIregs.FRMWyfov(mode)              = DFZ_regs.FRMW.yfov(mode);         % single         
        ROIregs.FRMWprojectionYshear(mode)  = DFZ_regs.FRMW.projectionYshear(mode); % single   
        ROIregs.FRMWlaserangleH             = DFZ_regs.FRMW.laserangleH;            % single   
        ROIregs.FRMWlaserangleV 			= DFZ_regs.FRMW.laserangleV;            % single   
        ROIregs.FRMWxres 					= regs.FRMW.xres;                       % uint16   (640)
        ROIregs.FRMWyres 					= regs.FRMW.yres;                       % uint16   (360)
        ROIregs.FRMWpolyVars 				= DFZ_regs.FRMW.polyVars;               % single x3
        ROIregs.FRMWpitchFixFactor 			= DFZ_regs.FRMW.pitchFixFactor;         % single (0)
        
        
else
        ROIregs.DIGG.sphericalOffset        = typecast(bitand(regs.DIGGsphericalOffset,hex2dec('0fff0fff')),'int16');
        ROIregs.DIGG.sphericalScale         = typecast(bitand(regs.DIGGsphericalScale ,hex2dec('0fff0fff')),'int16');
        ROIregs.GNRL.imgHsize               = uint16(regs.GNRL.imgHsize);
        ROIregs.GNRL.imgVsize               = uint16(regs.GNRL.imgVsize);
        ROIregs.FRMW.mirrorMovmentMode      = regs.FRMWmirrorMovmentMode; % uint16         (1)
        ROIregs.FRMW.marginB                = regs.FRMWmarginB;           % int16          (0)
        ROIregs.FRMW.marginL                = regs.FRMWmarginL;           % int16          (0)
        ROIregs.FRMW.marginR                = regs.FRMWmarginR;           % int16          (0)
        ROIregs.FRMW.marginT                = regs.FRMWmarginT;           % int16          (0)
        ROIregs.FRMW.guardBandH             = regs.FRMWguardBandH;        % single         (0)
        ROIregs.FRMW.guardBandV             = regs.FRMWguardBandV;        % single         (0)
        ROIregs.FRMW.xfov(mode)             = regs.FRMWxfov(mode);        % single         (65)
        ROIregs.FRMW.yfov(mode)             = regs.FRMWyfov(mode);        % single         (45)
        ROIregs.FRMW.projectionYshear(mode) = regs.FRMWprojectionYshear(mode); % single   (0)
        ROIregs.FRMW.laserangleH            = regs.FRMWlaserangleH;            % single   (0)
        ROIregs.FRMW.laserangleV 			= regs.FRMWlaserangleV;            % single   (0)
        ROIregs.FRMW.xres 					= regs.FRMWxres;                   % uint16   (640)
        ROIregs.FRMW.yres 					= regs.FRMWyres;                   % uint16   (360)
        ROIregs.FRMW.polyVars 				= regs.FRMWpolyVars;               % single x3[0 0 0]      
        ROIregs.FRMW.pitchFixFactor 		= regs.FRMWpitchFixFactor;         % single (0)

end        
end