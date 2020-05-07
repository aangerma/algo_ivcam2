function framesOut = loadZIRGBFrames(dirname, fileJump, LRS)
if exist('LRS','var') && LRS
        framesOut.i(:,:,1) = io.readGeneralBin(fullfile(fullfile(dirname,'ir.raw')), 'uint8', [768 1024]);
        framesOut.z(:,:,1) = io.readGeneralBin(fullfile(dirname,'depth.raw'), 'uint16', [768 1024]);
        framesOut.yuy2(:,:,1) = du.formats.readBinRGBImage(fullfile(dirname,'rgb.raw'), [1920 1080], 5); 
        return;
end
if OnlineCalibration.Globals.loadSingleScene
    nDepth = 1;
    nRgb = 2;
else
    nDepth = inf;
    nRgb = inf;
end
if exist('fileJump','var') && ~isempty(fileJump)
    skipVal = fileJump;
else
    skipVal  = 1;
end
IfilesTemp = dir(fullfile(dirname,'I_*'));
IfilesTemp = IfilesTemp(1:min(nDepth,numel(IfilesTemp)));
ix = 1:skipVal:numel(IfilesTemp);
Ifiles = IfilesTemp(ix);
splittedStr = strsplit(Ifiles(1).name,'_');
splittedStr = strsplit(splittedStr{3},'x');
for i = 1:numel(Ifiles)
    frames.i(:,:,i) = io.readGeneralBin(fullfile(Ifiles(i).folder,Ifiles(i).name),'uint8',[str2double(splittedStr{2}),str2double(splittedStr{1})]);
end
ZfilesTemp = dir(fullfile(dirname,'Z_*'));
ZfilesTemp = ZfilesTemp(1:min(nDepth,numel(ZfilesTemp)));
ix = 1:skipVal:numel(ZfilesTemp);
Zfiles = ZfilesTemp(ix);
splittedStr = strsplit(Zfiles(1).name,'_');
splittedStr = strsplit(splittedStr{3},'x');
for i = 1:numel(Zfiles)
    frames.z(:,:,i) = io.readGeneralBin(fullfile(Zfiles(i).folder,Zfiles(i).name),'uint16',[str2double(splittedStr{2}),str2double(splittedStr{1})]);
end
yuy2filesTemp = dir(fullfile(dirname,'YUY2_YUY2_*'));
yuy2filesTemp = yuy2filesTemp(1:min(nRgb,numel(yuy2filesTemp)));
ix = 1:skipVal:numel(yuy2filesTemp);
yuy2files = yuy2filesTemp(ix);
splittedStr = strsplit(yuy2files(1).name,'_');
splittedStr = strsplit(splittedStr{3},'x');
for i = 1:numel(yuy2files)
    [frames.yuy2(:,:,i),~] = du.formats.readBinRGBImage(fullfile(yuy2files(i).folder,yuy2files(i).name),[str2double(splittedStr{1}),str2double(splittedStr{2})],5);
end
if OnlineCalibration.Globals.loadSingleScene
    framesOut.z = frames.z;
    framesOut.i = frames.i;
    framesOut.yuy2 = frames.yuy2;
    return;
end
[ixDepthColorMatch,isColorIx] = matchClosestDepth2ColorTime(Ifiles,Zfiles,yuy2files);
if isColorIx
    for k = 1:numel(Zfiles)
        framesOut.yuy2(:,:,k) =  frames.yuy2(:,:,ixDepthColorMatch(k));
    end
    framesOut.z = frames.z;
    framesOut.i = frames.i;
else
    for k = 1:numel(yuy2files)
        framesOut.z(:,:,k) = frames.z(:,:,ixDepthColorMatch(k));
        framesOut.i(:,:,k) = frames.i(:,:,ixDepthColorMatch(k));
    end
    framesOut.yuy2 = frames.yuy2;
end
end

function [ixDepthColorMatch,isColorIx] = matchClosestDepth2ColorTime(Ifiles,Zfiles,yuy2files)
if numel(Ifiles) ~= numel(Zfiles)
%     error('Number of depth frames differs from IR frames!');
end
%%
[yuy2TimeTag] = getTimeTagFromDirDataIpDev(yuy2files);
[zTimeTag] = getTimeTagFromDirDataIpDev(Zfiles);
[iTimeTag] = getTimeTagFromDirDataIpDev(Ifiles);
diffVec = milliseconds(zTimeTag - iTimeTag);
[minFrames, iMin] = min([numel(yuy2TimeTag),numel(zTimeTag)]);
ixDepthColorMatch = zeros(minFrames,1);
for k = 1:minFrames
    if iMin == 1
        iThrowFrames = diffVec ~= milliseconds(0);
        if any(iThrowFrames)
            zTimeTag(iThrowFrames) = -1;
            warning('Some time tags are different between Z and IR!');
        end
        [~,ixDepthColorMatch(k)] = min(milliseconds(abs(yuy2TimeTag(k)-zTimeTag)));
        isColorIx = false;
    else
        [~,ixDepthColorMatch(k)] = min(milliseconds(abs(yuy2TimeTag-zTimeTag(k))));
        isColorIx = true;
    end
end

end

function [timeTagVec] = getTimeTagFromDirDataIpDev(dirData)
% timeTagVec = zeros(numel(dirData),1);
timeTagVec = duration(0,0,0,1:numel(dirData));

for k = 1:numel(dirData)
    splittedStr = strsplit(dirData(k).name,'.');
    split1 = strsplit(splittedStr{4},'_');
    timeTagVec(1,k) = milliseconds(str2double(split1{1})*1e-1);
    timeTagVec(1,k) = timeTagVec(1,k) + seconds(str2double(splittedStr{3}));
    timeTagVec(1,k) = timeTagVec(1,k) + minutes(str2double(splittedStr{2}));
    split2 = strsplit(splittedStr{1},'_');
    timeTagVec(1,k) = timeTagVec(1,k) + hours(str2double(split2{end}));
end
end