clear
close all
atcDir = '\\143.185.124.250\tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2837\12-12\F9340423\ATC13_SH_5_43';
videoType = 'Motion JPEG AVI';
videoName = 'C:\temp\F9340026.avi';
stop = struct;
stop.lddTmp = 30; % When to stop video recording in ldd
stop.timeInSec = 100;% When to stop video recording in time
frameRate = 4;

x = load(fullfile(atcDir,'Matlab','mat_files','finalCalcAfterHeating_in.mat'));
fd = Calibration.thermal.framesDataVectors(x.data.framesData);
thermalImagesDir = fullfile(atcDir,'Images','Thermal');
cycles = dir(thermalImagesDir);
cycles = cycles(3:end);
cyclesNum = (strsplit([cycles.name],'Cycle'));
cyclesNum = cellfun(@str2num,cyclesNum,'UniformOutput',0);
cyclesNum = [cyclesNum{:}];
[~,order] = sort(cyclesNum);

cycles = cycles(order);


%% Test the figure ans recalc teh colors
k = 1;
IRfn = dir(fullfile(cycles(k).folder,cycles(k).name,'I_480x1024_Cycle*.bin'));
if isempty(IRfn)
    IR = [];
else
    IRfn = fullfile(IRfn.folder,IRfn.name);
    IR = io.readGeneralBin(IRfn,'uint8',[1024,480])';
end
Zfn = dir(fullfile(cycles(k).folder,cycles(k).name,'Z_480x1024_Cycle*.bin'));
if isempty(Zfn)
    Z = [];
else
    Zfn = fullfile(Zfn.folder,Zfn.name);
    Z = io.readGeneralBin(Zfn,'uint16',[1024,480])';
end
RGBfn = dir(fullfile(cycles(k).folder,cycles(k).name,'RGB_1920x1080_Cycle*.bin'));
if isempty(RGBfn)
    RGB = [];
else
    RGBfn = fullfile(RGBfn.folder,RGBfn.name);
%         RGB = io.readGeneralBin(RGBfn,'uint16',[1080,1920]);
    [RGB,color] = du.formats.readBinRGBImage(RGBfn,[1920,1080],5);
end



zDistanceColorRange = [Z(240,500)/4-200,Z(240,500)/4+200];
IRColorRange = [min(IR(:)),max(IR(:))];
RGBColorRange = [0,255];
%%




figure('units','normalized','outerposition',[0 0 1 1]);
axis tight manual 
set(gca,'nextplot','replacechildren'); 
v = VideoWriter(videoName,videoType);
v.FrameRate = frameRate;
open(v);

for k = 1:numel(cycles)
    IRfn = dir(fullfile(cycles(k).folder,cycles(k).name,'I_480x1024_Cycle*.bin'));
    if isempty(IRfn)
        IR = [];
    else
        IRfn = fullfile(IRfn.folder,IRfn.name);
        IR = io.readGeneralBin(IRfn,'uint8',[1024,480])';
    end
    Zfn = dir(fullfile(cycles(k).folder,cycles(k).name,'Z_480x1024_Cycle*.bin'));
    if isempty(Zfn)
        Z = [];
    else
        Zfn = fullfile(Zfn.folder,Zfn.name);
        Z = io.readGeneralBin(Zfn,'uint16',[1024,480])';
    end
    RGBfn = dir(fullfile(cycles(k).folder,cycles(k).name,'RGB_1920x1080_Cycle*.bin'));
    if isempty(RGBfn)
        RGB = [];
    else
        RGBfn = fullfile(RGBfn.folder,RGBfn.name);
%         RGB = io.readGeneralBin(RGBfn,'uint16',[1080,1920]);
        [RGB,color] = du.formats.readBinRGBImage(RGBfn,[1920,1080],5);
    end
    stopVid = fillFigure(fd,Z,IR,RGB,k,zDistanceColorRange,IRColorRange,RGBColorRange,stop);
    
    frame = getframe(gcf);
    writeVideo(v,frame);
    if stopVid
       break; 
    end
end

close(v);
function stopVid = fillFigure(fd,Z,IR,RGB,iter,zDistanceColorRange,IRColorRange,RGBColorRange,stop)
stopVid = 0;
validCB = all(~isnan(fd.ptsWithZ(:,1,:)),3);
subplot(321);
imagesc(Z/4,zDistanceColorRange);
title(sprintf('Cycle%3d',iter))
subplot(322);
imagesc(IR,IRColorRange);
subplot(323);
imagesc(RGB);
subplot(324);
plot(fd.time(1:iter),fd.ldd(1:iter));
hold on
plot(fd.time(1:iter),fd.shtw2(1:iter),'r');
plot(fd.time(1:iter),fd.ldd(1:iter),'b');
plot(fd.time(1:iter),fd.tsense(1:iter),'g');
legend({'ldd';'hum';'tsense'})
title('temperatures')
grid minor
subplot(325);
plot(fd.time(1:iter),fd.irStatMean(1:iter));
title('mean IR')
grid minor
subplot(326);
plot(fd.time(1:iter),squeeze(mean(fd.ptsWithZ(validCB,1,1:iter),1)));
title('mean RTD')
grid minor

if fd.time(iter) > stop.timeInSec
    stopVid = 1;
end
if fd.ldd(iter) > stop.lddTmp
    stopVid = 1;
end
end