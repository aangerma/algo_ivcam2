function [params] = getCameraParamsRaw(sceneDir,params)
fid = fopen(fullfile(sceneDir,'camera_params.matlab'), 'rb');
binData = uint8(fread(fid));
fclose(fid);

ResSize = 2*8;
z_MMsize = 1*8;
Ksize = 9*8;
DistortSize = 5*8;
Rsize = 9*8;
Tsize = 3*8;
PMatSize = 12*8;

params.depthRes= typecast(binData(1:ResSize), 'double');
zMaxSubMMsize = ResSize + z_MMsize;
params.zMaxSubMM = typecast(binData(ResSize+1:zMaxSubMMsize), 'double');
KdepthSize = zMaxSubMMsize + Ksize;
params.Kdepth = typecast(binData(zMaxSubMMsize+1:KdepthSize), 'double');
params.Kdepth = reshape(params.Kdepth, 3,3)';
rgbRes = KdepthSize+ResSize;
params.rgbRes = typecast(binData(KdepthSize+1:rgbRes), 'double');
KrgbSize = rgbRes+Ksize;
params.Krgb = typecast(binData(rgbRes+1:KrgbSize), 'double');
params.Krgb = reshape(params.Krgb, 3,3)';
rgbDistort=KrgbSize+DistortSize;
params.rgbDistort = typecast(binData(KrgbSize+1:rgbDistort), 'double');
params.rgbDistort = params.rgbDistort';
Rrgb = rgbDistort+Rsize;
params.Rrgb = typecast(binData(rgbDistort+1:Rrgb), 'double');
params.Rrgb = reshape(params.Rrgb, 3,3)';
Trgb = Rrgb+Tsize;
params.Trgb = typecast(binData(Rrgb+1:Trgb), 'double');
rgbPmat = Trgb+PMatSize;
params.rgbPmat = typecast(binData(Trgb+1:rgbPmat), 'double');
params.rgbPmat = reshape(params.rgbPmat, 4,3)';



end

