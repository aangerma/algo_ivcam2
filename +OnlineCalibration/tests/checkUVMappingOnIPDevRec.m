
% 
%% Load frames from IPDev
dirname = 'C:\temp\onlineRGB';
subdir = fullfile(dirname,'F9340892','ZIRGB');

% Load data of scene 
frames = OnlineCalibration.aux.loadZIRGBFrames(subdir);

% Load unitData
load(fullfile(dirname,'F9340892','camerasParams.mat'));

% Take first frame
frame.z = frames.z(:,:,1);
frame.i = frames.i(:,:,1);
frame.yuy2 = frames.yuy2(:,:,1);
params = camerasParams;
params.cbGridSz = [9,13];


uvRMS = OnlineCalibration.Metrics.calcUVMappingErr(frame,params,1);


