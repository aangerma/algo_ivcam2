function [frame,paramsOut,acInputData] = iqFolderToAlgoInputs(folderPath)
load(fullfile(folderPath,'InputData.mat'),'frame','params','ac2_dsm_params');

colorData = dir(fullfile(folderPath,'color_*.bin'));
[res] = getResFromFileName(colorData.name);
rgbRes = [res(2),res(1)];
depthData = dir(fullfile(folderPath,'depth_*.bin'));
[depthRes] = getResFromFileName(depthData.name);
[paramsOut,acInputData] = parseIqToAlgoInputs(rgbRes,depthRes,params,ac2_dsm_params);

paramsOut.zMaxSubMM = 4;
frame.z = frame.z*4;

mkdirSafe(fullfile(folderPath,'\binFiles\ac2'));
OnlineCalibration.aux.saveBinImage(fullfile(folderPath,'\binFiles\ac2'),'depth', frame.z,'uint16');
OnlineCalibration.aux.saveBinImage(fullfile(folderPath,'\binFiles\ac2'),'ir', frame.i,'uint8');
yuy2 = uint16(frame.yuy2);
OnlineCalibration.aux.saveBinImage(fullfile(folderPath,'\binFiles\ac2'),'color', yuy2,'uint16');
yuy2_prev = uint16(frame.yuy2Prev);
OnlineCalibration.aux.saveBinImage(fullfile(folderPath,'\binFiles\ac2'),'previous_color',yuy2_prev,'uint16');
try
    yuy2filesTemp = dir(fullfile(folderPath,'previous_valid_color_*'));
    splittedStr = strsplit(yuy2filesTemp.name,'_');
    splittedStr = strsplit(splittedStr{4},'x');
    [frame.yuy2_prev_valid,~] = du.formats.readBinRGBImage(fullfile(yuy2filesTemp.folder,yuy2filesTemp.name),[str2double(splittedStr{2}), str2double(splittedStr{1})],5);
    yuy2_prev_valid = uint16(frame.yuy2_prev_valid);
catch
    yuy2_prev_valid = 0*frame.yuy2;
    frame.yuy2_prev_valid = yuy2_prev_valid;
end

OnlineCalibration.aux.saveBinImage(fullfile(folderPath,'\binFiles\ac2') ,'previous_valid_color',yuy2_prev_valid,'uint16');

frame.yuy_files(1) = dir(fullfile(folderPath ,'\binFiles\ac2', 'color_*'));
frame.yuy_files(2) = dir(fullfile(folderPath ,'\binFiles\ac2','previous_color_*'));
frame.yuy_files(3) = dir(fullfile(folderPath ,'\binFiles\ac2','previous_valid_color_*'));

frame.z_files(1) = dir(fullfile(folderPath ,'\binFiles\ac2', 'depth_*'));
frame.i_files(1) = dir(fullfile(folderPath ,'\binFiles\ac2','ir_*'));
try
    mdFile = dir(fullfile(folderPath,'../../**/md.json'));
    md = loadjson(fullfile(mdFile.folder,mdFile.name));
    paramsOut.preset = md.preset;
    paramsOut.apdGain = 18*strcmp(paramsOut.preset,'low_ambient') + 9*(1-strcmp(paramsOut.preset,'low_ambient'));
    paramsOut.mdFileContent = md;
end   
end


function [paramsOut,acInputData] = parseIqToAlgoInputs(rgbRes,depthRes,cameraParams,ac2DsmParams)
paramsOut.rgbRes = rgbRes;
paramsOut.depthRes = depthRes;
%%
rgbCalRes.Fx = cameraParams.Rgb.(strcat('Resolution',num2str(paramsOut.rgbRes(1)),'x',num2str(paramsOut.rgbRes(2)))).rFx;
rgbCalRes.Fy = cameraParams.Rgb.(strcat('Resolution',num2str(paramsOut.rgbRes(1)),'x',num2str(paramsOut.rgbRes(2)))).rFy;
rgbCalRes.Cy = cameraParams.Rgb.(strcat('Resolution',num2str(paramsOut.rgbRes(1)),'x',num2str(paramsOut.rgbRes(2)))).rPy;
rgbCalRes.Cx = cameraParams.Rgb.(strcat('Resolution',num2str(paramsOut.rgbRes(1)),'x',num2str(paramsOut.rgbRes(2)))).rPx;

paramsOut.Krgb = [rgbCalRes.Fx, 0, rgbCalRes.Cx;
    0, rgbCalRes.Fy, rgbCalRes.Cy;
    0, 0, 1];
%%
depthCalRes.Fx = cameraParams.Depth.(strcat('Resolution',num2str(paramsOut.depthRes(2)),'x',num2str(paramsOut.depthRes(1)))).rFx;
depthCalRes.Fy = cameraParams.Depth.(strcat('Resolution',num2str(paramsOut.depthRes(2)),'x',num2str(paramsOut.depthRes(1)))).rFy;
depthCalRes.Cy = cameraParams.Depth.(strcat('Resolution',num2str(paramsOut.depthRes(2)),'x',num2str(paramsOut.depthRes(1)))).rPy;
depthCalRes.Cx = cameraParams.Depth.(strcat('Resolution',num2str(paramsOut.depthRes(2)),'x',num2str(paramsOut.depthRes(1)))).rPx;

paramsOut.Kdepth = [depthCalRes.Fx, 0, depthCalRes.Cx;
    0, depthCalRes.Fy, depthCalRes.Cy;
    0, 0, 1];
%%
if iscell(cameraParams.Rgb.Distortion)
    paramsOut.rgbDistort = cell2mat(cameraParams.Rgb.Distortion);
else
    paramsOut.rgbDistort = cameraParams.Rgb.Distortion';
end
paramsOut.zMaxSubMM = 1;
if iscell(cameraParams.Rgb.Extrinsics.Depth.Translation)
    paramsOut.Trgb = cell2mat(cameraParams.Rgb.Extrinsics.Depth.Translation)';
else
    paramsOut.Trgb = cameraParams.Rgb.Extrinsics.Depth.Translation;
end
if iscell(cameraParams.Rgb.Extrinsics.Depth.RotationMatrix)
    paramsOut.Rrgb = reshape(cell2mat(cameraParams.Rgb.Extrinsics.Depth.RotationMatrix),[3,3])';
else
    paramsOut.Rrgb = reshape(cameraParams.Rgb.Extrinsics.Depth.RotationMatrix,[3,3])';
end
[paramsOut.xAlpha,paramsOut.yBeta,paramsOut.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(paramsOut.Rrgb);

paramsOut.rgbPmat = paramsOut.Krgb*[paramsOut.Rrgb, paramsOut.Trgb];
%%
acInputData.binWithHeaders = 1;
acInputData.calibDataBin  = ac2DsmParams.table_313;
acInputData.acDataBin  = ac2DsmParams.table_240;
acInputData.DSMRegs.dsmXscale = ac2DsmParams.extLdsmXscale;
acInputData.DSMRegs.dsmXoffset = ac2DsmParams.extLdsmXoffset;
acInputData.DSMRegs.dsmYscale = ac2DsmParams.extLdsmYscale;
acInputData.DSMRegs.dsmYoffset = ac2DsmParams.extLdsmYoffset;
end

function [res] = getResFromFileName(fileName)
strTemp = strsplit(fileName,'_');
strTemp = strsplit(strTemp{2},'x');
res = [str2double(strTemp{2}),str2double(strTemp{1})];
end