function [params] = getCameraParamsFromRsc(sceneDir,params)
fid = fopen(fullfile(sceneDir,'RecordingStatus.rsc'), 'rb');
binData = uint8(fread(fid));
fclose(fid);
[metaDataStruct] = io.loadIpDevRscFile(binData);
params.Rrgb = metaDataStruct.RGB_rotation;
params.rgbRes = [metaDataStruct.RGB_Horizontal_resolution metaDataStruct.RGB_Vertical_resolution];
params.rgbPmat = metaDataStruct.K_RGB*[metaDataStruct.RGB_rotation,metaDataStruct.RGB_translation];
params.rgbDistort = metaDataStruct.RGB_distortion;
params.Krgb = metaDataStruct.K_RGB;
params.depthRes = [metaDataStruct.Depth_Vertical_resolution metaDataStruct.Depth_Horizontal_resolution];
params.zMaxSubMM = metaDataStruct.Z_scale;
params.Kdepth = metaDataStruct.K_depth;
params.Trgb = metaDataStruct.RGB_translation;
end

