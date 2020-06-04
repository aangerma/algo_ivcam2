function [frame,paramsOut,acInputData] = iqFolderToAlgoInputs(folderPath)
load(fullfile(folderPath,'InputData.mat'),'frame','params','ac2_dsm_params');
colorData = dir(fullfile(folderPath,'color_*.bin'));
[res] = getResFromFileName(colorData.name);
rgbRes = [res(2),res(1)];
depthData = dir(fullfile(folderPath,'depth_*.bin'));
[depthRes] = getResFromFileName(depthData.name);
[paramsOut,acInputData] = parseIqToAlgoInputs(rgbRes,depthRes,params,ac2_dsm_params);
    
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