function startStream(obj)
    if(obj.m_dotnetcam.Stream.IsDepthPlaying)
        return;
    end
    
    %% configure for getFrames
    scwD = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.Z.ToString(),...
        IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
        30));
    
    scwI = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.I.ToString(),...
        IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
        30));
    
    scwC = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.C.ToString(),...
        IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir240x640,...
        30));
    
    scwList = NET.createGeneric('System.Collections.Generic.List',...
        {'IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper'});
    scwList.Add(scwD)
    scwList.Add(scwI)
    scwList.Add(scwC)
    camConfig = IVCam.Tools.CamerasSdk.Cameras.Configuration.CameraConfiguration(scwList);
    
    obj.m_dotnetcam.Stream.ConfigureAndPlay(camConfig);
    %% set regs configurations that affect image capturing
    pause(1);
    obj.setConfig();
end