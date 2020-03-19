function framesOut = loadZIRGBFrames(dirname)
    
    if OnlineCalibration.Globals.loadSingleScene
        nDepth = 1;
        nRgb = 2;
    else
        nDepth = inf;
        nRgb = inf;
    end

    Ifiles = dir(fullfile(dirname,'I_*'));
    Ifiles = Ifiles(1:min(nDepth,numel(Ifiles)));
    splittedStr = strsplit(Ifiles(1).name,'_');
    splittedStr = strsplit(splittedStr{3},'x');
    for i = 1:numel(Ifiles)
       frames.i(:,:,i) = io.readGeneralBin(fullfile(Ifiles(i).folder,Ifiles(i).name),'uint8',[str2double(splittedStr{2}),str2double(splittedStr{1})]);
    end
    Zfiles = dir(fullfile(dirname,'Z_*'));
    Zfiles = Zfiles(1:min(nDepth,numel(Zfiles)));
    splittedStr = strsplit(Zfiles(1).name,'_');
    splittedStr = strsplit(splittedStr{3},'x');
    for i = 1:numel(Zfiles)
       frames.z(:,:,i) = io.readGeneralBin(fullfile(Zfiles(i).folder,Zfiles(i).name),'uint16',[str2double(splittedStr{2}),str2double(splittedStr{1})]); 
    end
    yuy2files = dir(fullfile(dirname,'YUY2_YUY2_*'));
    yuy2files = yuy2files(1:min(nRgb,numel(yuy2files)));
    splittedStr = strsplit(yuy2files(1).name,'_');
    splittedStr = strsplit(splittedStr{3},'x');
    for i = 1:numel(yuy2files)
       [frames.yuy2(:,:,i),~] = du.formats.readBinRGBImage(fullfile(yuy2files(i).folder,yuy2files(i).name),[str2double(splittedStr{1}),str2double(splittedStr{2})],5);
    end
    ixDepthMatch2Color = matchClosestDepth2ColorTime(Ifiles,Zfiles,yuy2files);
    for k = 1:numel(yuy2files)
        framesOut.z(:,:,k) = frames.z(:,:,ixDepthMatch2Color(k));
        framesOut.i(:,:,k) = frames.i(:,:,ixDepthMatch2Color(k));
    end
    framesOut.yuy2 = frames.yuy2;
end

function [ixDepthMatch2Color] = matchClosestDepth2ColorTime(Ifiles,Zfiles,yuy2files)
if numel(Ifiles) ~= numel(Zfiles)
    error('Number of depth frames differs from IR frames!');
end
%%
[yuy2TimeTag] = getTimeTagFromDirDataIpDev(yuy2files);
[zTimeTag] = getTimeTagFromDirDataIpDev(Zfiles);
[iTimeTag] = getTimeTagFromDirDataIpDev(Ifiles);
diffVec = milliseconds(zTimeTag - iTimeTag);
iThrowFrames = diffVec ~= milliseconds(0);
zTimeTag(iThrowFrames) = -1;
iTimeTag(iThrowFrames) = -1;
ixDepthMatch2Color = zeros(numel(yuy2TimeTag),1);
for k = 1:numel(yuy2TimeTag)
    [~,ixDepthMatch2Color(k)] = min(milliseconds(abs(yuy2TimeTag(k)-zTimeTag)));
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