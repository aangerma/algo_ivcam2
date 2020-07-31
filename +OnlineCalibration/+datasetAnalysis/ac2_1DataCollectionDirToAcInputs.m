function [frame,params,dataForACTableGeneration] = ac2_1DataCollectionDirToAcInputs(main_dir)


scene_data_folder = dir(fullfile(main_dir,'**','InputData.mat'));

load(fullfile(scene_data_folder.folder,'InputData.mat'),'frame','params','ac2_dsm_params');
paramsFromFile = params;
params = [];
%% DSM params
% dataForACTableGeneration
dataForACTableGeneration.binWithHeaders = 1;
dataForACTableGeneration.DSMRegs.dsmYoffset = ac2_dsm_params.extLdsmYoffset;
dataForACTableGeneration.DSMRegs.dsmXoffset = ac2_dsm_params.extLdsmXoffset;
dataForACTableGeneration.DSMRegs.dsmYscale = ac2_dsm_params.extLdsmYscale;
dataForACTableGeneration.DSMRegs.dsmXscale = ac2_dsm_params.extLdsmXscale;
dataForACTableGeneration.calibDataBin = ac2_dsm_params.table_313;
dataForACTableGeneration.acDataBin = ac2_dsm_params.table_240;

%% params
params.depthRes = size(frame.i);
params.rgbRes = fliplr(size(frame.yuy2));

RGBcalRes.Fx = paramsFromFile.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rFx;
RGBcalRes.Fy = paramsFromFile.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rFy;
RGBcalRes.Cy = paramsFromFile.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rPy;
RGBcalRes.Cx = paramsFromFile.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rPx;

Kl = [RGBcalRes.Fx, 0, RGBcalRes.Cx;
      0, RGBcalRes.Fy, RGBcalRes.Cy;
      0, 0, 1];
params.Krgb = Kl;
%%
DepthcalRes.Fx = paramsFromFile.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rFx;
DepthcalRes.Fy = paramsFromFile.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rFy;
DepthcalRes.Cy = paramsFromFile.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rPy;
DepthcalRes.Cx = paramsFromFile.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rPx;

Kl = [DepthcalRes.Fx, 0, DepthcalRes.Cx;
      0, DepthcalRes.Fy, DepthcalRes.Cy;
      0, 0, 1];
params.Kdepth = Kl;
%%
params.rgbDistort = cell2mat(paramsFromFile.Rgb.Distortion);
params.Trgb = cell2mat(paramsFromFile.Rgb.Extrinsics.Depth.Translation)';
params.Rrgb = reshape(cell2mat(paramsFromFile.Rgb.Extrinsics.Depth.RotationMatrix),[3,3])';
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
params.rgbPmat = params.Krgb*[ params.Rrgb, params.Trgb];

[params] = OnlineCalibration.aux.getParamsForAC(params);
params.zMaxSubMM = 1;
params.outputFolder = fullfile(main_dir,'figures');

%% Debug
%{
calibFilename = fullfile(after_folder,'calibration.json');
lrsAfterCalib = loadjson(calibFilename);
calibFilename = fullfile(before_folder,'base_calibration.json');
beforeCalibNoModif = loadjson(calibFilename);
load('verticesZ2mm4.mat');
kRgbLrs = [lrsAfterCalib.Rgb.Resolution1280x720.rFx, 0, lrsAfterCalib.Rgb.Resolution1280x720.rPx;...
    0, lrsAfterCalib.Rgb.Resolution1280x720.rFy,lrsAfterCalib.Rgb.Resolution1280x720.rPy;...
    0,0,1];
Rlrs = reshape(lrsAfterCalib.Rgb.Extrinsics.Depth.RotationMatrix,3,3)';
Tlrs = lrsAfterCalib.Rgb.Extrinsics.Depth.Translation';
pMatLrs = kRgbLrs*[Rlrs,Tlrs];
p = 0;
[uvMapLrs,~,~] = OnlineCalibration.aux.projectVToRGB(verts,pMatLrs,kRgbLrs,lrsAfterCalib.Rgb.Distortion,p);
figure; imagesc(frame.yuy2);
hold on; plot(sceneResults.uvMapOrig(:,1),sceneResults.uvMapOrig(:,2),'+g');
hold on; plot(sceneResults.uvMapNew(:,1),sceneResults.uvMapNew(:,2),'+r');
hold on; plot(uvMapLrs(:,1),uvMapLrs(:,2),'+y');
%}

end

