testTime = 15;
filePath = 'C:\temp\rangeByVoltage\avrPicsOverTimeLaserWormup.mat';

%wormLaser
% hw.cmd('Iwb e2 11 01 0')
% hw.cmd('iwb e2 02 01 f2')
% hw.cmd('iwb e2 03 01 1a')
% hw.cmd('iwb e2 08 01 ff')
% hw.cmd('mwd fffe18a4 fffe18a8 00023fff')
% hw.cmd('mwd a00504d0 a00504d4 7000000')
% 
% toContinue = true
% hw = HWinterface();
% while toContinue
%     pause(3);
%     hw.getLddTemperature()
% end

hw = HWinterface();
hw.startStream();

%depth as range
hw.cmd('mwd a00e0894 a00e0898 00000001');
hw.cmd('mwd a00d01f4 a00d01f8 00000fff');

frame = struct('z',0,'i',0,'c',0);
mTemp = struct('lddTmptr',0,'mcTmptr',0,'maTmptr',0,'apdTmptr',0);
numOfFrames = 5;
start = clock;
i=1
while etime(clock, start) < testTime*60
    %get volatge
    hw.cmd('mwd b00a00c4 b00a00c8 19E662bC');
    volt = hw.cmd('MRD4 b00a00c8');
    voltD = (hex2dec(volt(end-2:end))+1157.2)/1865.8;
    mVoltage(i) = voltD;
    %get temp
    hw.cmd('mwd b00a00c4 b00a00c8 19E6623C');
    [lddTmptr,mcTmptr,maTmptr,apdTmptr] = hw.getLddTemperature();
    mTemp(i) =struct('lddTmptr',lddTmptr,'mcTmptr', mcTmptr,'maTmptr',maTmptr,'apdTmptr',apdTmptr);
    fprintf('voltage %s, temp: %s\n', voltD, lddTmptr);
    
    %take pic
    frame(i) = hw.getFrame(numOfFrames, true);
    pause(1);
    i = i+1;
end
%depth as depth
hw.cmd('mwd a00e0894 a00e0898 00000000');
hw.cmd('mwd a00d01f4 a00d01f8 00000fff');

save(filePath)


% 12122256
% 
figure;
hold on;
params.roi = 0.00001;
mask = Validation.aux.getRoiCircle(size(frame(1).z), params);
for i = 1:numel(frame)
    img = frame(i).z(601,350);
    zVals(:,i) = img./4; 
end
plot([mTemp(:).maTmptr ], zVals)
cof = polyfit([mTemp(:).maTmptr], single(zVals),1)
plot([mTemp(:).maTmptr ], [mTemp(:).maTmptr ]*cof(1)+ cof(2))

plot([mTemp(:).lddTmptr ], zVals)
cof2 = polyfit([mTemp(:).lddTmptr], single(zVals),1)
plot([mTemp(:).lddTmptr ], [mTemp(:).lddTmptr ]*cof2(1)+ cof2(2))
legend([{'maTemp'},{'maTempFit'},{'lddTemp'},{'lddTempFit'}])

xlabel('temperature')
ylabel('distance (mm)')

% 
