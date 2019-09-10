close all
clear variables
clc

%%

totalTime = 30*60; % [sec]
samplingTime = 0.5*60; % [sec]
switchingTime = 3*60; % [sec]

%%

hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.startStream(0,[480,640]);
curSyncLoopEn = 0;
hw.cmd(sprintf('ENABLE_SYNC_LOOP %d',curSyncLoopEn));
t0 = tic;
t1 = toc(t0);
tLastSwitch = tic;

Tldd = zeros(0,1);
delays = zeros(0,3);
syncLoopEn = zeros(0,1);
while (t1 < totalTime)
    t1 = toc(t0);
    Tldd(end+1,1) = hw.getLddTemperature;
    delayIR = hw.read('EXTLconLocDelaySlow');
    delayZC = hw.read('EXTLconLocDelayFastC');
    delayZF = hw.read('EXTLconLocDelayFastF');
    delays(end+1,:) = [delayIR, delayZC, delayZF];
    syncLoopEn(end+1,1) = curSyncLoopEn;
    tSwitch = toc(tLastSwitch);
    if (tSwitch > switchingTime)
        curSyncLoopEn = 1-curSyncLoopEn;
        hw.cmd(sprintf('ENABLE_SYNC_LOOP %d',curSyncLoopEn));
        tLastSwitch = tic;
    end
    fprintf('After %.0f[sec]: T = %.1f\n', t1, Tldd(end))
    pause(samplingTime)
end
hw.stopStream();

save('test_results.mat', 'Tldd', 'delays', 'syncLoopEn')


