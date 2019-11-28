filePath = 'C:\temp\rangeByTemp\coolDownCycleFrezeWithVolt3.mat';

global hw;
global zVals;
global mTemp;
global mTime;
global mVoltage;    

tic;
hw = HWinterface();
frame = struct('z',0,'i',0,'c',0);
mTemp = struct('lddTmptr',0,'mcTmptr',0,'maTmptr',0,'apdTmptr',0, 'humidityTmptr', 0);

%depth as range
hw.cmd('mwd a00e0894 a00e0898 00000001');
hw.cmd('mwd a00d01f4 a00d01f8 00000fff');

hw.cmd('DIRTYBITBYPASS')
getInfo(15);
% for i=1:10
%     t = randi(15)
%     getInfo(t);
%     t = randi(120)
%     coolDown(t);
% end
% getInfo(10);
% coolDown(2);
% lddWormUp(10)
% getInfo(5)
% lddCoolDown(5)
% getInfo(5)
% lddCoolDown(5)
% getInfo(5)

%depth as depth
hw.cmd('mwd a00e0894 a00e0898 00000000');
hw.cmd('mwd a00d01f4 a00d01f8 00000fff');
hw.stopStream()
save(filePath)

function getInfo(timeInMinutes)
    global hw;
    global zVals;
    global mTemp;
    global mTime;
    global mVoltage


    hw.startStream();
    numOfFrames = 5;
    start = clock;
    i=1;
    while etime(clock, start) < timeInMinutes*60
        %get volatge
        hw.cmd('mwd b00a00c4 b00a00c8 19E662bC');
        volt = hw.cmd('MRD4 b00a00c8');
        voltD = (hex2dec(volt(end-2:end))+1157.2)/1865.8;
        mVoltage(i) = voltD;
        %get temp
        hw.cmd('mwd b00a00c4 b00a00c8 19E6623C');
        [lddTmptr,mcTmptr,maTmptr,apdTmptr] = hw.getLddTemperature();
        humidityTmptr = hw.getHumidityTemperature();
        mTemp(i) =struct('lddTmptr',lddTmptr,'mcTmptr', mcTmptr,'maTmptr',maTmptr,'apdTmptr',apdTmptr, 'humidityTmptr', humidityTmptr);

        %take pic
        frame = hw.getFrame(numOfFrames, true);
        mTime(i)=toc;
        

        img = mean(mean(double(frame.z(401:420,400:420))));
        zVals(i) = img./4; 
        fprintf('time %d, Ldd: %d, Ma: %d, Apd: %d, Z: %d, volt: %d\n', mTime(i), lddTmptr, maTmptr, apdTmptr, zVals(i), mVoltage(i));

        pause(1);
        i = i+1;
    end
end

function coolDown(timeInMinutes)
    global hw
    hw.stopStream()
    pause(timeInMinutes)
end

function lddWormUp(timeInMinutes)
    global hw
    hw.cmd('Iwb e2 11 01 0')
    hw.cmd('iwb e2 02 01 f2')
    hw.cmd('iwb e2 03 01 1a')
    hw.cmd('iwb e2 08 01 ff')
    hw.cmd('mwd fffe18a4 fffe18a8 00023fff')
    hw.cmd('mwd a00504d0 a00504d4 7000000')
    pause(60*timeInMinutes)
    hw.cmd('rst')
    pause(60*timeInMinutes)
    hw = HWinterface()
end

function lddCoolDown(timeInMinutes)
    global hw
    hw.cmd('mwd a00504d0 a00504d4 5000000')
    pause(60*timeInMinutes)
    hw.cmd('rst')
    hw = HWinterface()
end

function plotTempRange()
    params.roi = 0.1;
    mask = Validation.aux.getRoiCircle(size(frame(1).z), params);
    for i = 1:numel(frame)
        img = mean(mean(double(frame(i).z(401:420,400:420))));
        zVals(:,i) = img./4; 
    end

    figure;
    hold on;
    maS = smooth([mTemp(:).maTmptr]);
    humS = smooth([mTemp(:).humidityTmptr]);
    lddS = smooth([mTemp(:).lddTmptr]);
    
    yyaxis left
    plot(t, [mTemp(:).maTmptr], 'DisplayName','maTmptr')
    plot(t, [mTemp(:).humidityTmptr], 'DisplayName','humidityTmptr')
    plot(t, [mTemp(:).lddTmptr], 'DisplayName','lddTmptr')
    
    plot(t, maS, 'DisplayName','maS')
    plot(t, humS, 'DisplayName','humS')
    plot(t, lddS, 'DisplayName','lddS')
  
    plot(t, lddS-maS, 'DisplayName','lddS-maS')
    plot(t, lddS-humS, 'DisplayName','lddS-humS')
    
    yyaxis right
    plot(t, zVals, 'DisplayName','zVals')

    
    figure; hold on;
    plot([mTemp(:).maTmptr ], zVals);
    
    plot([mTemp(:).maTmptr ], zVals);
    plot(t, [mTemp(:).humidityTmptr]);
    
    plot([mTemp(:).lddTmptr ], zVals);
    
    
    
    cof = polyfit([mTemp(:).maTmptr], single(zVals),1)
    plot([mTemp(:).maTmptr ], [mTemp(:).maTmptr ]*cof(1)+ cof(2))

    plot([mTemp(:).lddTmptr ], zVals)
    cof2 = polyfit([mTemp(:).lddTmptr], single(zVals),1)
    plot([mTemp(:).lddTmptr ], [mTemp(:).lddTmptr ]*cof2(1)+ cof2(2))
    legend([{'maTemp'},{'maTempFit'},{'lddTemp'},{'lddTempFit'}])

    xlabel('temperature')
    ylabel('distance (mm)')

end
function plotTempRangeTime()
figure;
hold on;

avg = conv(zVals, ones(1,31)/31, 'same')
t= [1: numel(zVals)]

yyaxis left
plot(t, [mTemp(:).maTmptr])
cof = polyfit([mTemp(:).maTmptr], single(zVals),1)
plot([mTemp(:).maTmptr ], [mTemp(:).maTmptr ]*cof(1)+ cof(2))

plot(t, [mTemp(:).lddTmptr])
cof2 = polyfit([mTemp(:).lddTmptr], single(zVals),1)
plot([mTemp(:).lddTmptr ], [mTemp(:).lddTmptr ]*cof2(1)+ cof2(2))
legendNames = [{'maTemp'},{'maTempFit'},{'lddTemp'},{'lddTempFit'}]
legend(legendNames)
ylabel('temperature')
xlabel('time (sec)')

yyaxis right
plot(t, avg);
A = [[mTemp(:).lddTmptr]', [mTemp(:).maTmptr]', c'];
X = A\transpose(avg)
y = X(1)*[mTemp.lddTmptr] + X(2)*[mTemp.maTmptr]+X(3);
plot(t, y, 'g');
legendNames = [legendNames, {'avrageRange'}, {'calculatedRange'}]
legend(legendNames)
end