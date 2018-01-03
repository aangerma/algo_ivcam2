
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

%add all .net dlls
% % % asm = cell(length(d),1);
% % % s = {};
% % % gen = {};
% % % asmNames = {...  
% % % %     'AssemblyHandle';...
% % %     'Classes';...
% % %     'Structures';...
% % %     'Enums';...
% % %     'GenericTypes';...
% % %     'Interfaces';...
% % %     'Delegates'};
% % % 
% % % s = struct();
% % % for i= 1:length(asmNames)
% % %     s.(asmNames{i}) = {};
% % % end

for i=1:length(d)
    f = fullfile(p,d{i});
     NET.addAssembly(f);
    
    
% % %     for j= 1:length(asmNames)
% % %         s.(asmNames{j})(end+1:end+length((asm{i}.(asmNames{j})))) = (asm{i}.(asmNames{j}));
% % %     end
    
%     s(end+1:end+length((asm{i}.Classes))) = (asm{i}.Classes);
%     gen(end+1:end+length((asm{i}.GenericTypes))) = (asm{i}.GenericTypes);
end
% % % for i= 1:length(asmNames)
% % %     s.(asmNames{i}) = vec(sort(s.(asmNames{i})));
% % % end

%%

% % % t = NET.createGeneric('System.Collections.Generic.List',{'System.Double'},10);
% % % a = 
% % % 
% % % dmType = NET.GenericClass(...
% % %     'IVCam.Tools.CamerasSdk.Cameras.DeviceManager',...
% % %     'IVCam.Tools.CamerasSdk.Cameras.Generic.IVCam20.Devices.IVCam20DeviceDetails');


%%

dm = NET.createGeneric('IVCam.Tools.CamerasSdk.Cameras.DeviceManager',...
 {'IVCam.Tools.CamerasSdk.Cameras.Generic.IVCam20.Devices.IVCam20DeviceDetails'});

cam = dm.CameraFactory.CreateFirstAvailableCamera;
%%
str = System.String('MRD 40001000 40001004');
result = cam.HwFacade.CommandsService.Send(str);

%%
   %{
cam.Stream.ConfigureAndPlay(new CameraConfiguration(
    new List<StreamConfigurationWrapper>
            {
                new StreamConfigurationWrapper(CompositeDeviceType.Depth,...
                new StreamConfiguration(IVCam20DepthMode.Z.ToString(), eImageResolution.ir480x640, 30))
            }
));
%}
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
cam.Stream.ConfigureAndPlay(camConfig);


imageCollection = cam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth);
depthImage = imageCollection.Images.First();
rawData = depthImage[0].Data;

cam.Close();