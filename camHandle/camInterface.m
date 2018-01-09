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
            %% upload all dlls
            %get all .dll in dir
            p = fullfile(pwd,'IVCam20Device');
            d = dir(fullfile(p,'*.dll'));
            
            d = {d.name};
            
            %no need to addAssembly of cpp .dlls
            not_net_dll = {'DepthCameras.Common.dll','DepthCameras.UVC.dll','DepthCameras.WinUsb.dll' ,'IVCAM1_5.dll'};
            not_net_dll_Ind = false(size(d));
            for i=1:length(not_net_dll)
                not_net_dll_Ind = strcmp(not_net_dll{i},d) | not_net_dll_Ind;
            end
            dnet = d;
            dnet(not_net_dll_Ind) = [];
            
            for i=1:length(dnet)
                f = fullfile(p,dnet{i});
                try
                    NET.addAssembly(f);
                catch e
                    e
                end
                
            end
            %% create cam obj
            dm = NET.createGeneric('IVCam.Tools.CamerasSdk.Cameras.DeviceManager',...
                {'IVCam.Tools.CamerasSdk.Cameras.Generic.IVCam20.Devices.IVCam20DeviceDetails'});
            
            if(0)
                %% logger data for debug
                dm.LoggerManager.CamerasSdkLogger.SetLogDirectory(System.String('Z:\\Yaniv\\For Ohad\\IVCam20Sample\\'))
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
            newObj.m_cam = cam;
            
        end
        
        function delete(obj)
            obj.m_cam.Close();
        end
        
        
        function res = cmd(obj,str)
            sysstr = System.String(str);
            result = obj.m_cam.HwFacade.CommandsService.Send(sysstr);
            if(~result.IsCompletedOk)
                error(char(result.ErrorMessage))
            end
            res = char(result.ResultFormatted);
        end
        
        
        function frame = getFrame(obj)
            imageCollection = obj.m_cam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth);
            % get depth
            imageObj = imageCollection.Images.Item(0);
            dImByte = imageObj.Item(0).Data;
            frame.z = reshape(typecast(cast(dImByte,'uint8'),'uint16'),480,640);
            
            % get IR
            imageObj = imageCollection.Images.Item(1);
            iImByte = imageObj.Item(0).Data;
            frame.i = reshape(cast(iImByte,'uint8'),480,640);
            
            % get C
            imageObj = imageCollection.Images.Item(2);
            cImByte = imageObj.Item(0).Data;
            cIm8 = cast(cImByte,'uint8');
            cIm8cell = num2cell(cIm8);
            t = cellfun(@(x) [x/2^4; mod(x,2^4)],cIm8cell,'uni',0);
            tt = cell2mat(t);
            tt = tt(:);
            frame.c = reshape(tt,480,640);
            
            if(0)
                %%
                figure(2525232);clf;
                tabplot;imagesc(frame.z);
                tabplot;imagesc(frame.i);
                tabplot;imagesc(frame.c);
            end
        end
    end
end



