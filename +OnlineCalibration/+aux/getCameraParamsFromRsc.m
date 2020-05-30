function [params] = getCameraParamsFromRsc(sceneDir,params)
fid = fopen(fullfile(sceneDir,'RecordingStatus.rsc'), 'rb');
binData = uint8(fread(fid));
fclose(fid);
[metaDataStruct] = io.loadIpDevRscFile(binData);
params.Rrgb = double(metaDataStruct.RGB_rotation);
params.rgbRes = [metaDataStruct.RGB_Horizontal_resolution metaDataStruct.RGB_Vertical_resolution];
params.rgbPmat = double(metaDataStruct.K_RGB)*[double(metaDataStruct.RGB_rotation),double(metaDataStruct.RGB_translation)];
params.rgbDistort = double(metaDataStruct.RGB_distortion);
params.Krgb = double(metaDataStruct.K_RGB);
params.depthRes = [metaDataStruct.Depth_Vertical_resolution metaDataStruct.Depth_Horizontal_resolution];
params.zMaxSubMM = double(metaDataStruct.Z_scale);
params.Kdepth = double(metaDataStruct.K_depth);
params.Trgb = double(metaDataStruct.RGB_translation);
params.captureLdd = metaDataStruct.LDD;
params.captureHumT = metaDataStruct.HumidityT;
end

