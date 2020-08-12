function [ frame, params,dataForACTableGeneration] = getCameraParamsRaw(main_dir)
scene_data_folder = dir(fullfile(main_dir,'**','cal.registers'));
scene_data_folder = scene_data_folder.folder;

main_dir_subfolders = dir(main_dir);
main_dir_subfolders = {main_dir_subfolders(:).name}';

% tmp = regexp(main_dir_subfolders,'md\_\d+','match');
% metadata_folder_ind = ~cellfun('isempty',tmp);
% metadata_folder = fullfile(main_dir,main_dir_subfolders{metadata_folder_ind});
% 
% tmp = regexp(main_dir_subfolders,'iteration\d+\_after','match');
% after_folder_ind = ~cellfun('isempty',tmp);
% after_folder = fullfile(main_dir,main_dir_subfolders{after_folder_ind});
% 
% tmp = regexp(main_dir_subfolders,'iteration\d+\_before','match');
% before_folder_ind = ~cellfun('isempty',tmp);
% before_folder = fullfile(main_dir,main_dir_subfolders{before_folder_ind});
%% DSM params
regsFilename = fullfile(scene_data_folder,'cal.registers');
table240Filename = fullfile(scene_data_folder,'dsm.params');
table313Filename = fullfile(scene_data_folder,'cal.info');

fid = fopen(regsFilename,'r+');
% regsVec = typecast(fread(fid,inf,'uint32'),'double');
regsVec = fread(fid,'double');
fclose(fid);

fid = fopen(table240Filename,'r+');
table240Vec = fread(fid,inf,'uint8');
fclose(fid);

fid = fopen(table313Filename,'rb');
table313Vec = fread(fid,inf,'*uint8');
fclose(fid);
% fw = Firmware;
% regs = fw.readAlgoEpromData(table313Vec);

dataForACTableGeneration.binWithHeaders = false;
% dataForACTableGeneration.DSMRegs.dsmYoffset = typecast(single(regs.EXTL.dsmYoffset),'uint32');
% dataForACTableGeneration.DSMRegs.dsmXoffset = typecast(single(regs.EXTL.dsmXoffset),'uint32');
% dataForACTableGeneration.DSMRegs.dsmYscale = typecast(single(regs.EXTL.dsmYscale),'uint32');
% dataForACTableGeneration.DSMRegs.dsmXscale = typecast(single(regs.EXTL.dsmXscale),'uint32');
dataForACTableGeneration.dsmRegs.dsmYoffset = typecast(single(regsVec(4)),'uint32');
dataForACTableGeneration.dsmRegs.dsmXoffset = typecast(single(regsVec(3)),'uint32');
dataForACTableGeneration.dsmRegs.dsmYscale = typecast(single(regsVec(2)),'uint32');
dataForACTableGeneration.dsmRegs.dsmXscale = typecast(single(regsVec(1)),'uint32');
dataForACTableGeneration.calibDataBin = table313Vec';
dataForACTableGeneration.acDataBin = table240Vec';

%% Params
fid = fopen(fullfile(scene_data_folder,'rgb.calib'), 'rb');
binData = uint8(fread(fid));
fclose(fid);

ixBin = 1;
intBytes = 4;
doubleBytes = 8;
params.Rrgb = reshape(typecast(binData(ixBin:ixBin+9*doubleBytes-1), 'double'),3,3)';
ixBin = ixBin+9*doubleBytes;
params.Trgb = typecast(binData(ixBin:ixBin+3*doubleBytes-1), 'double');
ixBin = ixBin+3*doubleBytes;
params.Krgb = reshape(typecast(binData(ixBin:ixBin+9*doubleBytes-1), 'double'),3,3)';
ixBin = ixBin+9*doubleBytes;
params.rgbRes(1) = double(typecast(binData(ixBin:ixBin+intBytes-1), 'uint32'));
ixBin = ixBin+intBytes;
params.rgbRes(2) = double(typecast(binData(ixBin:ixBin+intBytes-1), 'uint32'));
ixBin = ixBin+3*intBytes;
params.rgbDistort = typecast(binData(ixBin:ixBin+5*doubleBytes-1), 'double')';

fid = fopen(fullfile(scene_data_folder,'depth.intrinsics'), 'rb');
binData = uint8(fread(fid));
fclose(fid);
ixBin = 1;
params.depthRes(2) = double(typecast(binData(ixBin:ixBin+intBytes-1), 'uint32'));
ixBin = ixBin+intBytes;
params.depthRes(1) = double(typecast(binData(ixBin:ixBin+intBytes-1), 'uint32'));
ixBin = ixBin+intBytes;
ppx = typecast(binData(ixBin:ixBin+doubleBytes-1), 'double');
ixBin = ixBin+doubleBytes;
ppy = typecast(binData(ixBin:ixBin+doubleBytes-1), 'double');
ixBin = ixBin+doubleBytes;
fx = typecast(binData(ixBin:ixBin+doubleBytes-1), 'double');
ixBin = ixBin+doubleBytes;
fy = typecast(binData(ixBin:ixBin+doubleBytes-1), 'double');
params.Kdepth = [fx,0,ppx;0,fy,ppy;0,0,1];
params.rgbPmat = params.Krgb*[params.Rrgb params.Trgb];

% fid = fopen(fullfile(scene_data_folder,'camera_params'), 'rb');
% binData = uint8(fread(fid));
% fclose(fid);

% ResSize = 2*8;
% z_MMsize = 1*8;
% Ksize = 9*8;
% DistortSize = 5*8;
% Rsize = 9*8;
% Tsize = 3*8;
% PMatSize = 12*8;
% 
% params.depthRes= typecast(binData(1:ResSize), 'double');
% params.depthRes = flip(params.depthRes)';
% zMaxSubMMsize = ResSize + z_MMsize;
% params.zMaxSubMM = typecast(binData(ResSize+1:zMaxSubMMsize), 'double');
% KdepthSize = zMaxSubMMsize + Ksize;
% params.Kdepth = typecast(binData(zMaxSubMMsize+1:KdepthSize), 'double');
% params.Kdepth = reshape(params.Kdepth, 3,3)';
% rgbRes = KdepthSize+ResSize;
% params.rgbRes = typecast(binData(KdepthSize+1:rgbRes), 'double');
% params.rgbRes = params.rgbRes';
% KrgbSize = rgbRes+Ksize;
% params.Krgb = typecast(binData(rgbRes+1:KrgbSize), 'double');
% params.Krgb = reshape(params.Krgb, 3,3)';
% rgbDistort=KrgbSize+DistortSize;
% params.rgbDistort = typecast(binData(KrgbSize+1:rgbDistort), 'double');
% params.rgbDistort = params.rgbDistort';
% Rrgb = rgbDistort+Rsize;
% params.Rrgb = typecast(binData(rgbDistort+1:Rrgb), 'double');
% params.Rrgb = reshape(params.Rrgb, 3,3)';
% Trgb = Rrgb+Tsize;
% params.Trgb = typecast(binData(Rrgb+1:Trgb), 'double');
% rgbPmat = Trgb+PMatSize;
% % params.rgbPmat = typecast(binData(Trgb+1:rgbPmat), 'double');
% % params.rgbPmat = reshape(params.rgbPmat, 4,3)';
% 
% params.rgbPmat = params.Krgb*[params.Rrgb params.Trgb];
% 
% % iterNum = strsplit(main_dir,'iteration');
% % iterNum = iterNum{end};
% % mdData = loadjson(fullfile(main_dir,['md_' iterNum],'md.json'));
% % splittedProfile = strsplit(mdData.profile,' ');
% % Params.rgbRes = [str2double(splittedProfile{12}), str2double(splittedProfile{14})];%[1280 720];
% % Params.depthRes = [str2double(splittedProfile{5}), str2double(splittedProfile{3})];%[480 640];
% % 
% % calibFilename = fullfile(before_folder,'modified_calibration.json');
% % 
% % % fid = fopen(calibFilename,'r+');
% % % jsonIn = fread(fid,inf,'char');
% % % fclose(fid);
% % % jsonIn = char(jsonIn);
% % % CalibData = jsondecode(jsonIn);
% % CalibData = loadjson(calibFilename);
% % 
% % RGBcalRes.Fx = CalibData.Rgb.(strcat('Resolution',num2str(Params.rgbRes(1)),'x',num2str(Params.rgbRes(2)))).rFx;
% % RGBcalRes.Fy = CalibData.Rgb.(strcat('Resolution',num2str(Params.rgbRes(1)),'x',num2str(Params.rgbRes(2)))).rFy;
% % RGBcalRes.Cy = CalibData.Rgb.(strcat('Resolution',num2str(Params.rgbRes(1)),'x',num2str(Params.rgbRes(2)))).rPy;
% % RGBcalRes.Cx = CalibData.Rgb.(strcat('Resolution',num2str(Params.rgbRes(1)),'x',num2str(Params.rgbRes(2)))).rPx;
% % 
% % Kl = [RGBcalRes.Fx, 0, RGBcalRes.Cx;
% %       0, RGBcalRes.Fy, RGBcalRes.Cy;
% %       0, 0, 1];
% % Params.Krgb = Kl;
% % %%
% % DepthcalRes.Fx = CalibData.Depth.(strcat('Resolution',num2str(Params.depthRes(2)),'x',num2str(Params.depthRes(1)))).rFx;
% % DepthcalRes.Fy = CalibData.Depth.(strcat('Resolution',num2str(Params.depthRes(2)),'x',num2str(Params.depthRes(1)))).rFy;
% % DepthcalRes.Cy = CalibData.Depth.(strcat('Resolution',num2str(Params.depthRes(2)),'x',num2str(Params.depthRes(1)))).rPy;
% % DepthcalRes.Cx = CalibData.Depth.(strcat('Resolution',num2str(Params.depthRes(2)),'x',num2str(Params.depthRes(1)))).rPx;
% % 
% % Kl = [DepthcalRes.Fx, 0, DepthcalRes.Cx;
% %       0, DepthcalRes.Fy, DepthcalRes.Cy;
% %       0, 0, 1];
% % Params.Kdepth = Kl;
% % %%
% % Params.rgbDistort = CalibData.Rgb.Distortion;
% % 
% % Params.Trgb = CalibData.Rgb.Extrinsics.Depth.Translation';
% % Params.Rrgb = reshape(CalibData.Rgb.Extrinsics.Depth.RotationMatrix,[3,3])';
% % [Params.xAlpha,Params.yBeta,Params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(Params.Rrgb);
% % Params.rgbPmat = Params.Krgb*[ Params.Rrgb, Params.Trgb];
% 
[params] = OnlineCalibration.aux.getParamsForAC(params);
params.zMaxSubMM = 4;

%% rename and save all the images with the expected format
current_folder = pwd;
cd(scene_data_folder)
old = 'ir.raw';
new = strcat('ir_',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)),'_.raw');
frame_ir = fullfile(scene_data_folder,new);
copyfile(old,new)
old = 'depth.raw';
new = strcat('depth_',num2str(params.depthRes(2)),'x',num2str(params.depthRes(1)),'_.raw');
frame_depth = fullfile(scene_data_folder,new);
copyfile(old,new)
old = 'rgb.raw';
new = strcat('rgb_',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)),'_.raw');
frame_color = fullfile(scene_data_folder,new);
copyfile(old,new)
old = 'rgb_prev.raw';
new = strcat('rgb_prev_',num2str(params.rgbRes(1)),'x',num2str(params.rgbRes(2)),'_.raw');
frame_color_prev = fullfile(scene_data_folder,new);
copyfile(old,new)
cd(current_folder)

frame.yuy_files(1) = dir(frame_color);
frame.yuy_files(2) = dir(frame_color_prev);
frame.z_files(1) = dir(frame_depth);
frame.i_files(1) = dir(frame_ir);
%%
frame.i(:,:,1) = io.readGeneralBin(fullfile(fullfile(scene_data_folder,'ir.raw')), 'uint8', [params.depthRes(1) params.depthRes(2)]);
frame.z(:,:,1) = io.readGeneralBin(fullfile(scene_data_folder,'depth.raw'), 'uint16', [params.depthRes(1) params.depthRes(2)]);
%frame.z(:,:) = frame.z(:,:)*4;
frame.yuy2(:,:,1) = du.formats.readBinRGBImage(fullfile(scene_data_folder,'rgb.raw'), [params.rgbRes(1) params.rgbRes(2)], 5);
frame.yuy2Prev(:,:,1) = du.formats.readBinRGBImage(fullfile(scene_data_folder,'rgb_prev.raw'), [params.rgbRes(1) params.rgbRes(2)], 5);

end

