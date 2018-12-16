function startStream(obj,FrameGraberMode,resolution)
    timeout = 10; %timeout until first frame is valid
    if(obj.m_dotnetcam.Stream.IsDepthPlaying)
        return;
    end
        if(~exist('FrameGraberMode'))
        FrameGraberMode = false;
    end
    
    if(~exist('resolution'))
        resolution = [720 1280];
    end

 %   FrameGraberMode = true;

    
    if (FrameGraberMode == true)
        FG_startStream(obj,resolution);
    else 
    	imgVsize = obj.read('GNRLimgVsize');
    	if imgVsize == 360 || imgVsize == 180
        	eImageResolution = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir360x640;
        	eImageResolutionConf = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir180x640;
    	elseif imgVsize == 480 || imgVsize == 240
           	eImageResolution = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640;
        	eImageResolutionConf = IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir240x640;
    	end
	    %% configure for getFrames
	    scwD = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
	        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
	        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
	        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.Z.ToString(),...
	        eImageResolution,...
	        30));
	%         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
    
	    scwI = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
	        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
	        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
	        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.I.ToString(),...
	        eImageResolution,...
	        30));
	%         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
    
	    scwC = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
	        IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
	        IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
	        IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.C.ToString(),...
	        eImageResolutionConf,...
	        30));
	%         IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir240x640,...
    
	    scwList = NET.createGeneric('System.Collections.Generic.List',...
	        {'IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper'});
	    scwList.Add(scwD)
	    scwList.Add(scwI)
	    scwList.Add(scwC)
	    camConfig = IVCam.Tools.CamerasSdk.Cameras.Configuration.CameraConfiguration(scwList);
    
	    obj.m_dotnetcam.Stream.ConfigureAndPlay(camConfig);
	    %% set regs configurations that affect image capturing
	    pause(timeout);
	    obj.setSize();
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

