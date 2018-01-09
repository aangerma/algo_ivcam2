
if(exist('cam','var'))
    cam.Close();
end
clear mex
clear all
clc


%% upload all dlls
%get all .dll in dir
p = fullfile(pwd,'Resources');
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

dm.LoggerManager.CamerasSdkLogger.SetLogDirectory(System.String('Z:\\Yaniv\\For Ohad\\IVCam20Sample\\'))

cam = dm.CameraFactory.CreateFirstAvailableCamera();

%% read command
 str = System.String('mrd a0070200 a0070204'); %debug reg
  result = cam.HwFacade.CommandsService.Send(str);
  if(~result.IsCompletedOk)
  error(char(result.ErrorMessage))
  end
  res0 = char(result.ResultFormatted);
resF = res0(end-7:end)
%% write command
 str = System.String('mwd a0070200 a0070204 000000D2');
  result = cam.HwFacade.CommandsService.Send(str);
  if(~result.IsCompletedOk)
  error(char(result.ErrorMessage))
  end
%   res1 = char(result.ResultFormatted)
  
  str = System.String('mwd a00b01f0 a00b01f4 8');%shadow update
  result = cam.HwFacade.CommandsService.Send(str);
  if(~result.IsCompletedOk)
  error(char(result.ErrorMessage))
  end
%   res2 = char(result.ResultFormatted)
  
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

%% get frame
imageCollection = cam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth);
% get depth
depthImageObj = imageCollection.Images.Item(0);
dImByte = depthImageObj.Item(0).Data;
dImg16 = reshape(typecast(cast(dImByte,'uint8'),'uint16'),480,640);

figure;imagesc(dImg16)

% get IR
depthImageObj = imageCollection.Images.Item(1);
dImByte = depthImageObj.Item(0).Data;
dImg16 = reshape(cast(dImByte,'uint8'),480,640);

figure;imagesc(dImg16)

% get C
depthImageObj = imageCollection.Images.Item(2);
dImByte = depthImageObj.Item(0).Data;
cIm8 = cast(dImByte,'uint8');
cIm8cell = num2cell(cIm8);
t = cellfun(@(x) [x/2^4; mod(x,2^4)],cIm8cell,'uni',0);
tt = cell2mat(t);
tt = tt(:);


dImg16 = reshape(tt,480,640);

figure;imagesc(dImg16)
%% end

cam.Close();