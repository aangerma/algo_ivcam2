% Concrete singleton implementation
classdef camInterface <handle
    
    properties (Access=private)
        m_cam;
    end
    
    
    
    
    
    methods (Static=true, Access=private)
        %
    end
    
    methods (Access=private)
        %
    end
    
    methods (Access=public)
        
        function newObj = camInterface()
            
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
            
            newObj.m_cam = cam;
            
        end
        
        function delete(obj)
            obj.m_cam.close();
        end
        
        
        function result = cmd(obj,str)
            sysstr = System.String(str);
            %?????
        end
        
        
        function rawData = getFrame(obj)
            %?????????????????
        end
    end
end



