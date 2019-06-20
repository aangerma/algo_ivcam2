function startStream(obj,FrameGraberMode,resolution,colorResolution,rgbFR)
timeout = 10; %timeout until first frame is valid
if(obj.m_dotnetcam.Stream.IsDepthPlaying)
    return;
end

if ~exist('FrameGraberMode','var') || isempty(FrameGraberMode)
    FrameGraberMode = false;
end


if ~exist('resolution','var') || isempty(resolution)
    resolution = [720 1280];
end
obj.m_streamWithcolor = false;
if ~exist('colorResolution','var')
    colorResolution = [];
end
if ~exist('rgbFR','var')
    rgbFR = 30;
end

%   FrameGraberMode = true;


if (FrameGraberMode == true)
    FG_startStream(obj,resolution);
else
        fps = int32(30);
    RawWidth=double(obj.read('GNRLimgVsize'));
    RawHeight=double(obj.read('GNRLimgHsize'));
    
    % case for xga with upscale on Y
    if(RawWidth==384 && RawHeight==1024)
        RawWidth=2*RawWidth;
        
    end
        %}
        if RawWidth == 180 || RawWidth == 240
            RawWidth = RawWidth*2;
        elseif RawWidth == 232
            fps = int32(10);
        end
        RawWidth = int32(RawWidth);
        RawHeight = int32(RawHeight);
    
    %% configure for getFrames
    
    scwD = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.Z.ToString(),...
        RawWidth,RawHeight,...
        fps));
    %         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
    
    scwI = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.I.ToString(),...
        RawWidth,RawHeight,...
        fps));
    %         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
    
    scwC = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.C.ToString(),...
        RawWidth/2,RawHeight,...
        fps));
    %         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir240x640,...
    
    
    scwList = NET.createGeneric('System.Collections.Generic.List',...
        {'IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper'});
    scwList.Add(scwD)
    scwList.Add(scwI)
    scwList.Add(scwC)
    
    if ~isempty(colorResolution)
        eImageResolutionColor = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir1920x1080;
        scwColor = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
            IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Color,...
            IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
            IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20ColorMode.YUY2.ToString(),...
            eImageResolutionColor,...
            rgbFR));
        scwList.Add(scwColor);
        obj.m_streamWithcolor = true;
        
    end
    
    camConfig = IVCam.Tools.CamerasSdk.Cameras.Configuration.CameraConfiguration(scwList);
    
    obj.m_dotnetcam.Stream.ConfigureAndPlay(camConfig);
    %% set regs configurations that affect image capturing
    pause(timeout);
    obj.setUsefullRegs();
end
end


function FG_startStream(obj,resolution)
timeout = 1; %timeout until first frame is valid
%% configure for getFrames
if(resolution == [720 1280])
    scwFG = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.FG.ToString(),...
        IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir1280x720,...
        30));
else if (resolution == [600,800])
        scwFG = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
            IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
            IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
            IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.FG.ToString(),...
            IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir800x600,...
            30));
    else
        return;
    end
end


scwList = NET.createGeneric('System.Collections.Generic.List',...
    {'IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper'});

scwList.Add(scwFG)
camConfig = IVCam.Tools.CamerasSdk.Cameras.Configuration.CameraConfiguration(scwList);

obj.m_dotnetcam.Stream.ConfigureAndPlay(camConfig);
%% set regs configurations that affect image capturing
pause(timeout);
obj.setSize();
end

