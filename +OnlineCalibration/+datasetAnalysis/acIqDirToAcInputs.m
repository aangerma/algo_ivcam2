function [frame,params,dataForACTableGeneration] = acIqDirToAcInputs(main_dir)

scene_data_folder = dir(fullfile(main_dir,'**','*cal.registers'));
matFileFormat = 0;
if isempty(scene_data_folder)
    scene_data_folder = dir(fullfile(main_dir,'**','InputData.mat'));
    load(fullfile(scene_data_folder.folder,'InputData.mat'),'params','ac2_dsm_params');
    matFileFormat = 1;
end
scene_data_folder = scene_data_folder.folder;

main_dir_subfolders = dir(main_dir);
main_dir_subfolders = {main_dir_subfolders(:).name}';

tmp = regexp(main_dir_subfolders,'md\_\d+','match');
metadata_folder_ind = ~cellfun('isempty',tmp);
metadata_folder = fullfile(main_dir,main_dir_subfolders{metadata_folder_ind});

tmp = regexp(main_dir_subfolders,'iteration\d+\_after','match');
after_folder_ind = ~cellfun('isempty',tmp);
after_folder = fullfile(main_dir,main_dir_subfolders{after_folder_ind});

tmp = regexp(main_dir_subfolders,'iteration\d+\_before','match');
before_folder_ind = ~cellfun('isempty',tmp);
before_folder = fullfile(main_dir,main_dir_subfolders{before_folder_ind});
%% DSM params
if matFileFormat
     % dataForACTableGeneration
    dataForACTableGeneration.binWithHeaders = 1;
    dataForACTableGeneration.DSMRegs.dsmYoffset = ac2_dsm_params.extLdsmYoffset;
    dataForACTableGeneration.DSMRegs.dsmXoffset = ac2_dsm_params.extLdsmXoffset;
    dataForACTableGeneration.DSMRegs.dsmYscale = ac2_dsm_params.extLdsmYscale;
    dataForACTableGeneration.DSMRegs.dsmXscale = ac2_dsm_params.extLdsmXscale;
    dataForACTableGeneration.calibDataBin = ac2_dsm_params.table_313;
    dataForACTableGeneration.acDataBin = ac2_dsm_params.table_240;
else
    regsFilename = dir(fullfile(main_dir,'**','*cal.registers'));
    regsFilename = fullfile(regsFilename.folder,regsFilename.name);
    table240Filename = dir(fullfile(main_dir,'**','*dsm.params'));
    table240Filename = fullfile(table240Filename.folder,table240Filename.name);
    table313Filename = dir(fullfile(main_dir,'**','*cal.info'));
    table313Filename = fullfile(table313Filename.folder,table313Filename.name);
    
    % regsFilename = fullfile(scene_data_folder,'cal.registers');
    % table240Filename = fullfile(scene_data_folder,'dsm.params');
    % table313Filename = fullfile(scene_data_folder,'cal.info');
    
    fid = fopen(regsFilename,'r');
    % regsVec = typecast(fread(fid,inf,'uint32'),'double');
    regsVec = fread(fid,'double');
    fclose(fid);
    
    fid = fopen(table240Filename,'r');
    table240Vec = fread(fid,inf,'uint8');
    fclose(fid);
    
    fid = fopen(table313Filename,'rb');
    table313Vec = fread(fid,inf,'*uint8');
    fclose(fid);
    
    % dataForACTableGeneration
    dataForACTableGeneration.binWithHeaders = false;
    dataForACTableGeneration.DSMRegs.dsmYoffset = typecast(single(regsVec(4)),'uint32');
    dataForACTableGeneration.DSMRegs.dsmXoffset = typecast(single(regsVec(3)),'uint32');
    dataForACTableGeneration.DSMRegs.dsmYscale = typecast(single(regsVec(2)),'uint32');
    dataForACTableGeneration.DSMRegs.dsmXscale = typecast(single(regsVec(1)),'uint32');
    dataForACTableGeneration.calibDataBin = table313Vec';
    dataForACTableGeneration.acDataBin = table240Vec';
end
%% params
iterNum = strsplit(main_dir,'iteration');
iterNum = iterNum{end};
mdData = loadjson(fullfile(main_dir,['md_' iterNum],'md.json'));
splittedProfile = strsplit(mdData.profile,' ');
di = find(contains(splittedProfile,'depth'));
ri = find(contains(splittedProfile,'color'));
params.depthRes = [str2double(splittedProfile{di+4}), str2double(splittedProfile{di+2})];%[1280 720];
params.rgbRes = [str2double(splittedProfile{ri+2}), str2double(splittedProfile{ri+4})];%[480 640];

calibFilename = fullfile(before_folder,'modified_calibration.json');
CalibData = loadjson(calibFilename);

RGBcalRes.Fx = CalibData.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rFx;
RGBcalRes.Fy = CalibData.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rFy;
RGBcalRes.Cy = CalibData.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rPy;
RGBcalRes.Cx = CalibData.Rgb.(strcat('Resolution',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)))).rPx;

Kl = [RGBcalRes.Fx, 0, RGBcalRes.Cx;
      0, RGBcalRes.Fy, RGBcalRes.Cy;
      0, 0, 1];
params.Krgb = Kl;
%%
DepthcalRes.Fx = CalibData.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rFx;
DepthcalRes.Fy = CalibData.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rFy;
DepthcalRes.Cy = CalibData.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rPy;
DepthcalRes.Cx = CalibData.Depth.(strcat('Resolution',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)))).rPx;

Kl = [DepthcalRes.Fx, 0, DepthcalRes.Cx;
      0, DepthcalRes.Fy, DepthcalRes.Cy;
      0, 0, 1];
params.Kdepth = Kl;
%%
params.rgbDistort = CalibData.Rgb.Distortion;
params.Trgb = CalibData.Rgb.Extrinsics.Depth.Translation';
params.Rrgb = reshape(CalibData.Rgb.Extrinsics.Depth.RotationMatrix,[3,3])';
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
params.rgbPmat = params.Krgb*[ params.Rrgb, params.Trgb];

[params] = OnlineCalibration.aux.getParamsForAC(params);
params.zMaxSubMM = 4;

%% rename and save all the images with the expected format
if matFileFormat
    frame_ir = dir(fullfile(scene_data_folder,'ir_*.bin'));
    frame_ir = fullfile(frame_ir.folder,frame_ir.name);
    frame_depth = dir(fullfile(scene_data_folder,'depth_*.bin'));
    frame_depth = fullfile(frame_depth.folder,frame_depth.name);
    frame_color = dir(fullfile(scene_data_folder,'color_*.bin'));
    frame_color = fullfile(frame_color.folder,frame_color.name);
    frame_color_prev = dir(fullfile(scene_data_folder,'previous_color_*.bin'));
    frame_color_prev = fullfile(frame_color_prev.folder,frame_color_prev.name);
else
    frame_ir = dir(fullfile(scene_data_folder,'*ir.raw'));
    frame_ir = fullfile(frame_ir.folder,frame_ir.name);
    frame_depth = dir(fullfile(scene_data_folder,'*depth.raw'));
    frame_depth = fullfile(frame_depth.folder,frame_depth.name);
    frame_color = dir(fullfile(scene_data_folder,'*rgb.raw'));
    frame_color = fullfile(frame_color.folder,frame_color.name);
    frame_color_prev = dir(fullfile(scene_data_folder,'*rgb_prev.raw'));
    frame_color_prev = fullfile(frame_color_prev.folder,frame_color_prev.name);
end


%%
frame.i(:,:,1) = io.readGeneralBin(frame_ir, 'uint8', [params.depthRes(1) params.depthRes(2)]);
frame.z(:,:,1) = io.readGeneralBin(frame_depth, 'uint16', [params.depthRes(1) params.depthRes(2)]);
frame.yuy2(:,:,1) = du.formats.readBinRGBImage(frame_color, [params.rgbRes(1) params.rgbRes(2)], 5);
frame.yuy2Prev(:,:,1) = du.formats.readBinRGBImage(frame_color_prev, [params.rgbRes(1) params.rgbRes(2)], 5);

% figure; subplot(3,1,1); imagesc(frame.i); title('IR');
% subplot(3,1,2); imagesc(frame.z); title('Z');
% subplot(3,1,3); imagesc(frame.yuy2); title('YUY2');

% [validparams,params,newAcDataTable,newAcDataStruct,sceneResults] = OnlineCalibration.aux.runSingleACIteration(frame,params,params,dataForACTableGeneration);

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

