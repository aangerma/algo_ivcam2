% Concrete singleton implementation
classdef IPdev <handle
    
    properties (Access=private)
        cam;
    end
    
    
    
    
    
    methods (Static=true, Access=private)
        %
    end
    
    methods (Access=private)
        %
    end
    
    methods (Access=public)
        
        function newObj = IPdev()
            
            %get all .dll in dir
            p = fullfile(pwd,'IVCam20Device');
            d = dir(fullfile(p,'*.dll'));
            d = {d.name};
            
            
            %no need to addAssembly of cpp .dlls
            cpp_dll = { 'DepthCameras.Common.dll'  ,  'DepthCameras.UVC.dll'  ,  'DepthCameras.WinUsb.dll' ,   'IVCAM1_5.dll'};
            cpp_dllInd = false(size(d));
            for i=1:length(cpp_dll)
                cpp_dllInd = strcmp(cpp_dll{i},d) | cpp_dllInd;
            end
            d(cpp_dllInd) = [];
            
            for i=1:length(d)
                f = fullfile(p,d{i});
                NET.addAssembly(f);
                
            end
            
            dm = NET.createGeneric('IVCam.Tools.CamerasSdk.Cameras.DeviceManager',...
                {'IVCam.Tools.CamerasSdk.Cameras.Generic.IVCam20.Devices.IVCam20DeviceDetails'});
            cam = dm.CameraFactory.CreateFirstAvailableCamera;
            
            newObj.cam = cam;

        end
        
        
        function result = cmd(str)
            sysstr = System.String(str);
            result = obj.cam.HwFacade.CommandsService.Send(sysstr);
        end
        %           function wrfn(obj,fn)%newRegs,newLuts)%write immediate
        %               spWriteCommand(['dfgd ' fn]);
        %           end
        
        function rawData = getFrame(obj)
            scw = IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper(...
                IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,...
                IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfiguration(...
                IVCam.Tools.CamerasSdk.Common.Configuration.IVCam20.IVCam20DepthMode.Z.ToString(),...
                IVCam.Tools.CamerasSdk.Common.Configuration.eImageResolution.ir480x640,...
                30));
            
            
            scwList = NET.createGeneric('System.Collections.Generic.List',...
                {'IVCam.Tools.CamerasSdk.Cameras.Configuration.StreamConfigurationWrapper'});
            scwList.Add(scw)
            
            camConfig = IVCam.Tools.CamerasSdk.Cameras.Configuration.CameraConfiguration(scwList);
            
            %% ===stream===
            obj.cam.Stream.ConfigureAndPlay(camConfig);
            
            
            imageCollection = obj.cam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth);
            depthImage = imageCollection.Images.First();
            rawData = depthImage(0).Data;
        end
    end
end



