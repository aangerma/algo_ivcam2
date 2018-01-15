function obj=privInitCam(obj)
           %% upload all dlls
            %get all .dll in dir
            p = fullfile(fileparts(mfilename('fullpath')),'IVCam20Device',filesep);
            dnet = dirFiles(p,'*.dll',false);
            %no need to addAssembly of cpp .dlls
            not_net_dll = {'DepthCameras.Common.dll','DepthCameras.UVC.dll','DepthCameras.WinUsb.dll' ,'IVCAM1_5.dll'};
            
            dnet(cellfun(@(x) any(strcmpi(x,not_net_dll)),dnet))=[];
            dnet=strcat(p,dnet);
            cellfun(@(x) NET.addAssembly(x),dnet,'uni',0);
          
            %% create cam obj
            dm = NET.createGeneric('IVCam.Tools.CamerasSdk.Cameras.DeviceManager',...
                {'IVCam.Tools.CamerasSdk.Cameras.Generic.IVCam20.Devices.IVCam20DeviceDetails'});
            
            if(0)
                %% logger data for debug
                dm.LoggerManager.CamerasSdkLogger.SetLogDirectory(System.String('c:\\temp\\IVCam20Sample\\'));%#ok
            end
            
            cam = dm.CameraFactory.CreateFirstAvailableCamera();
            
            %% configure for getFrame
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
            
            cam.Stream.ConfigureAndPlay(camConfig);
            
            %%
            obj.m_dotnetcam = cam;
end