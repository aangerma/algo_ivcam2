% voltage = {'1EF','3BF','49F','69F','74F','8FF','ABF','C7F','E3F','FFF','11BF','138F','154F','170F','18CF'};
% mVoltage = [];
% mTemp = struct('lddTmptr',0,'mcTmptr',0,'maTmptr',0,'apdTmptr',0);
% 
% hw = HWinterface();
% hw.startStream();
% filePath = 'C:\temp\rangeByVoltage\avrPics.mat';
% 
% %depth as range
% hw.cmd('mwd a00e0894 a00e0898 00000001');
% hw.cmd('mwd a00d01f4 a00d01f8 00000fff');
% frame = struct('z',0,'i',0,'c',0);
% for i = 1:numel(voltage)
%     %change voltage
%     hw.cmd('mwd a0040004 a0040008 FFF');
%     hw.cmd(sprintf('%s %s', 'mwd a0040078 a004007c', voltage{i}));
%     hw.cmd('mwd a0040074 a0040078 1');
%     hw.cmd('mwd a0010100 a0010104 1020003F');
%     
%     %get volatge
%     hw.cmd('mwd b00a00c4 b00a00c8 19E662bC');
%     volt = hw.cmd('MRD4 b00a00c8');
%     voltD = (hex2dec(volt(end-2:end))+1157.2)/1865.8;
%     mVoltage(i) = voltD;
%     %get temp
%     hw.cmd('mwd b00a00c4 b00a00c8 19E6623C');
%     [lddTmptr,mcTmptr,maTmptr,apdTmptr] = hw.getLddTemperature();
%     mTemp(i) =struct('lddTmptr',lddTmptr,'mcTmptr', mcTmptr,'maTmptr',maTmptr,'apdTmptr',apdTmptr);
%     disp(sprintf('voltage %s, temp: %s', voltD, lddTmptr));
%     
%     %take pic
%     frame(i) = hw.getFrame(100, true);
% end
% %depth as depth
% hw.cmd('mwd a00e0894 a00e0898 00000000');
% hw.cmd('mwd a00d01f4 a00d01f8 00000fff');
% 
% save(filePath)
% 

figure;
hold on;
params.roi = 0.1;
mask = Validation.aux.getRoiCircle(size(frame(1).z), params);
for i = 1:numel(frame)
    img = frame(i).z(mask);
    zVals(:,i) = img./4; 
end
yyaxis left
plot(mVoltage, zVals)


hold on;
t = fieldnames(mTemp)
for i = 1:numel(t)
    yyaxis right
    plot(mVoltage, [mTemp(:).(t{i})])
end
legend(t)
grid minor

yyaxis right
ylabel('temperature')

yyaxis left
ylabel('distance (mm)')

xlabel('pvt vdd')


