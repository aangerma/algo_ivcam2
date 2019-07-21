function startStream(obj,FrameGraberMode,resolution,colorResolution,rgbFR)
timeout = 10; %timeout until first frame is valid
if(obj.m_dotnetcam.Stream.IsDepthPlaying)
    return;
end

if ~exist('FrameGraberMode','var') || isempty(FrameGraberMode)
    FrameGraberMode = false;
end


if ~exist('resolution','var') || isempty(resolution)
    if (FrameGraberMode)
        resolution = [720 1280];
    else
        resolution = [768 1024];
        warning('Resolution was not set by user. setting resolution to default (XGA)');
    end
end
obj.m_streamWithcolor = false;
if ~exist('colorResolution','var')
    colorResolution = [];
end
    obj.m_colorResolution = colorResolution;
if ~exist('rgbFR','var')
    rgbFR = 30;
end
    obj.m_rgbFR = rgbFR;
%   FrameGraberMode = true;


if (FrameGraberMode == true)
    FG_startStream(obj,resolution);
else
    fps = int32(30);
    imgVsize = resolution(1);
    imgHsize = resolution(2);
    %IVCam.Tools.CamerasSdk.Common.Configuration.ImageResolutionExtensions.GetImageResolution()
    %{
        if imgVsize == 360 || imgVsize == 180
        	eImageResolution = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir360x640;
        	eImageResolutionConf = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir180x640;
    	elseif imgVsize == 480 || imgVsize == 240
           	eImageResolution = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640;
        	eImageResolutionConf = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir240x640;
        elseif imgVsize == 232 %for L520
            eImageResolution = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.irDefault;
            eImageResolutionConf = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.irDefault;
            fps = 10;
    	end
    %}
    if imgVsize == 180 || imgVsize == 240
        imgVsize = imgVsize*2;
    elseif imgVsize == 232
        fps = int32(10);
    end
    imgVsize = int32(imgVsize);
    imgHsize = int32(imgHsize);
    
    %% configure for getFrames
    scwD = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.Z.ToString(),...
        imgVsize,imgHsize,...
        fps));
    %         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
    
    scwI = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.I.ToString(),...
        imgVsize,imgHsize,...
        fps));
    %         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
    scwC = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.C.ToString(),...
        imgVsize/2,imgHsize,...
        fps));
    %         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir240x640,...
    
    scwList = NET.createGeneric('System.Collections.Generic.List',...
        {'IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper'});
    scwList.Add(scwD)
    scwList.Add(scwI)
    scwList.Add(scwC)
    
    if ~isempty(colorResolution)
             %eImageResolutionColor = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir1920x1080;
            scwColor = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
                IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Color,...
                IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
                IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20ColorMode.YUY2.ToString(),...
                colorResolution(1),colorResolution(2),...
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

