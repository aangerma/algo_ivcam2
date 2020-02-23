function [camerasParams] = getCameraParamsFromRsc(sceneDir)
fid = fopen(fullfile(sceneDir,'RecordingStatus.rsc'), 'rb');
binData = uint8(fread(fid));
fclose(fid);
[metaDataStruct] = io.loadIpDevRscFile(binData);
camerasParams.Rrgb = metaDataStruct.RGB_rotation;
camerasParams.rgbRes = [metaDataStruct.RGB_Horizontal_resolution metaDataStruct.RGB_Vertical_resolution];
camerasParams.rgbPmat = metaDataStruct.K_RGB*[metaDataStruct.RGB_rotation,metaDataStruct.RGB_translation];
camerasParams.rgbDistort = metaDataStruct.RGB_distortion;
camerasParams.Krgb = metaDataStruct.K_RGB;
camerasParams.depthRes = [metaDataStruct.Depth_Vertical_resolution metaDataStruct.Depth_Horizontal_resolution];
camerasParams.zMaxSubMM = metaDataStruct.Z_scale;
camerasParams.Kdepth = metaDataStruct.K_depth;
camerasParams.Trgb = metaDataStruct.RGB_translation;
end

