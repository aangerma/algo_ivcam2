path = '\\rslabs-nas\VIDB\WW48_2019\sid_2019-11-26--14-15-35\IVCAM2IQTESTS\IQTest-IVCam2WallVGA\target_Wall\00000000f9340638\1';
pattern = 'Wall_Depth_300_640x480_*bin';
KPath = '\\rslabs-nas\VIDB\WW48_2019\sid_2019-11-26--14-15-35\IVCAM2IQTESTS\IQTest-IVCam2WallVGA\target_Wall\00000000f9340638\1\CalibrationTable.bin';
res = [480,640];
titlestr = '300';
files = dir(fullfile(path,pattern));

params = Validation.aux.defaultMetricsParams;
params.roi = 1;
params.roiCropRect = 0;

params.camera.zMaxSubMM = 4;
kVec = double(OpenFile( KPath,8,1,1,'float'));
params.camera.K = [kVec(1:3);kVec(4:6);[kVec(7:8) 1]];
    
for i = 1:numel(files)
   fname = fullfile(files(i).folder, files(i).name);
   frames(i).z = io.readGeneralBin(fname,'uint16',res);
   frames(i).i = ones(res);
end

indices = round(res(1)/2-20):round(res(1)/2+20);
for i = 1:numel(files)
    z = zeros(res);
    z(indices,:) = frames(i).z(indices,:);
    frames(i).z = z;
end
[score,~,dbg] = Validation.metrics.planeFit(frames,params);


figure,
subplot(121);
imagesc(dbg.distIm(:,:,end))
subplot(122);
plot(mean(dbg.distIm(indices,:,end)));
hold on
plot([res(2)-80,res(2)-80],minmax(mean(dbg.distIm(indices,:,end))));
title(titlestr)