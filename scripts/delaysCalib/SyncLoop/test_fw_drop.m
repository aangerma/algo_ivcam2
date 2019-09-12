close all
clear variables
clc

%% Temporal definitions
% totalTime = 30*60; % [sec]
% samplingTime = 0.5*60; % [sec]
% switchingTime = 3*60; % [sec]
totalTime = 15*60; % [sec]
samplingTime = 0.2*60; % [sec]
switchingTime = 1*60; % [sec]
changeTime = 8*60; % [sec]

%% Change definition
IR_slope    = 1.38;
IR_delay    = 97104;
Z_slope     = 1.05;
Z_delay     = 97245;
Tref        = 47.3;
DRAMconLocDelayFastC = uint32(8*floor(Z_delay/8));
DRAMconLocDelayFastF = uint32(mod(Z_delay,8));
DRAMconLocDelaySlow  = uint32(2^31)+(uint32(Z_delay)-uint32(IR_delay));
changeOccurred = false;
%TODO: have a variable tracking changeOccurred


%% Actual test

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
    if ~changeOccurred && (t1 >= changeTime)
        hw.cmd(sprintf('ENABLE_SYNC_LOOP %d',0));
        pause(1)
        hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 1 %s', dec2hex(DRAMconLocDelayFastC)))
        hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 2 %s', dec2hex(DRAMconLocDelayFastF)))
        hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 3 %s', dec2hex(DRAMconLocDelaySlow)))
        hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 4 %s', cell2mat(single2hex(Z_slope))))
        hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 5 %s', cell2mat(single2hex(IR_slope))))
        hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 6 %s', cell2mat(single2hex(Tref))))
        hw.cmd(sprintf('ENABLE_SYNC_LOOP %d',curSyncLoopEn));
        changeOccurred = true;
    end
    pause(samplingTime)
end
hw.stopStream();

save('test_results_drop59.mat', 'Tldd', 'delays', 'syncLoopEn')









