function [frames] = readTargetDir(path)

frames = [];

zFiles = dir([path '\*_Depth_640x480_*.bin']);
iFiles = dir([path '\*_IR_640x480_*.bin']);

nImages = length(zFiles);
if (nImages ~= length(zFiles))
    warning('numbers of depth and ir images do match'); 
end

for i=1:nImages
    frames(i).z = io.readBin(fullfile(path, zFiles(i).name), 'type', 'bin16');
    frames(i).i = io.readBin(fullfile(path, iFiles(i).name), 'type', 'bin8');
end

end

