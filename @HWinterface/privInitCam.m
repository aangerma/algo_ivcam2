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
            
            obj.m_dotnetcam = dm.CameraFactory.CreateFirstAvailableCamera();            
end