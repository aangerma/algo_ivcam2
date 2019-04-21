%folder = 'C:\Program Files (x86)\IVCAM.2.0.Tool\HWMonitorServer\Records\offset_0000\';
%folder = 'C:\Program Files (x86)\IVCAM.2.0.Tool\HWMonitorServer\Records\offset_3000\';
%folder = 'C:\Program Files (x86)\IVCAM.2.0.Tool\HWMonitorServer\Records\offset_0000_0314\';
folder = 'C:\Program Files (x86)\IVCAM.2.0.Tool\HWMonitorServer\Records\offsets_0-25000\';
fLogs = dir([folder '*.csv']);

for i=1:length(fLogs)
    f = fLogs(i).name;
    mcLog(i) = readPZRs([folder f]);
end

figure; hold on
for iLog=1:length(mcLog)
    plot(mcLog(iLog).angX, mcLog(iLog).angY, '.-'); title(sprintf('%u',iLog))
    %pause
end

figure(17); hold on
for i=1:length(mcLog)/3
    for j=1:3
        iLog = (i-1)*3+j;
        plot(mcLog(iLog).angX, mcLog(iLog).angY, '.-'); title(sprintf('%u',iLog));
    end
    pause
end


figure(19); hold on;
for i=1:length(mcLog)
    plot(mcLog(i).PZR3, '.-');
end

regs.DIGG.sphericalScale(2) = 360;
regs.DIGG.sphericalOffset(2) = 180;

iLog = 1;
angxQ = (mcLog(iLog).angX+regs.EXTL.dsmXoffset)*regs.EXTL.dsmXscale - 2047;
angyQ = (mcLog(iLog).angY+regs.EXTL.dsmYoffset)*regs.EXTL.dsmYscale - 2047;
figure; plot(mcLog(i).angX, mcLog(i).angY, '.-');
figure; plot(angxQ,angyQ,'.-');


xx = double(angxQ);
xx = xx*double(regs.DIGG.sphericalScale(1));
xx = xx/2^10; % bitshift(xx,-12+2);
xx = xx+double(regs.DIGG.sphericalOffset(1));
xx = xx/4;

yy = double(angyQ);
yy = yy*double(regs.DIGG.sphericalScale(2));
yy = yy/2^12; % bitshift(yy,-12);
yy = yy+double(regs.DIGG.sphericalOffset(2));

[xx, yy] = angle2sphericalXY(mcLog(iLog).angX, mcLog(iLog).angY, regs);
figure; plot(xx, yy, '.-');

[angX,angY] = sphericalXY2angle(xx,yy,regs);
figure; plot(angX,angY, '.-');

