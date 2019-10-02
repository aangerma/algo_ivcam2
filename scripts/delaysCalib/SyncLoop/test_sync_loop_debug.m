close all
clear variables
clc


%% Preparations

% Delay regs definitions
Z_delay_Algo1   = 98473;
IR_delay_Algo1  = 98359;

Z_delay_eeprom  = 98477;
IR_delay_eeprom = 98362;

% Z_delays            = [98507, 98634, 97957, 98226, 98599];
% Z_delays            = [98507, 98634, 98057, 98226, 98599];
Z_delays            = [98507, 98634, 98057, 98226, 97599];
% Z_delays            = [90507, 85634, 77957, 70226, 65599]; % giantfix
% Z_delays            = [98707, 98934, 99157, 99326, 99599]; % bigfix
conLocDelayFastC    = zeros(1,length(Z_delays),'uint32');
conLocDelayFastF    = zeros(1,length(Z_delays),'uint32');
for k = 1:length(Z_delays)
    conLocDelayFastC(k) = uint32(8*floor(Z_delays(k)/8));
    conLocDelayFastF(k) = uint32(mod(Z_delays(k),8));
end

% Initializations
res             = [480,640]; % VGA
nFrameToAv      = 30;
delays          = zeros(0,3,'uint32');
tmptrOffset     = zeros(0,1);
rangeImage      = zeros(res(1),res(2),0,'uint16');

useReset    = 0;
useShadow   = 0;
useManual   = 0;
useSyncLoop = 1;

%% Actual test

% Initializations
hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.setAlgoLoops(false, false);
if useSyncLoop
    hw.cmd('SET_PARAM_SYNC_LOOP 1 180A8');
    hw.cmd('SET_PARAM_SYNC_LOOP 2 2');
    hw.cmd('SET_PARAM_SYNC_LOOP 3 80000073');
    hw.cmd('SET_PARAM_SYNC_LOOP 4 00000000');
    hw.cmd('SET_PARAM_SYNC_LOOP 5 00000000');
    hw.setAlgoLoops(true, false);
end
hw.cmd('mwd a00d01f0 a00d01f4 00000003'); % enable shadow update for PMG ( +PI)
hw.startStream(0,res);
hw.cmd('mwd a00e18b8 a00e18bc FFFF0000'); % skip min-range invalidation
hw.cmd('mwd a00e0894 a00e0898 00000001'); % output depth as range
hw.cmd('mwd a00e0868 a00e086c 00000000'); % baseline
hw.cmd('mwd a00e086c a00e0870 00000000'); % baseline2
hw.shadowUpdate();

% Actual test
for iEvent = 1:length(Z_delays)+1
    pause(5);
    fprintf('Reading from unit (step %d / %d)\n', iEvent, length(Z_delays)+1)
    delayIR = hw.read('EXTLconLocDelaySlow');
    delayZC = hw.read('EXTLconLocDelayFastC');
    delayZF = hw.read('EXTLconLocDelayFastF');
    delays(end+1,:) = [delayIR, delayZC, delayZF];
    tmptrOffset(end+1,1) = typecast(hw.read('DESTtmptrOffset'), 'single');
    frame = hw.getFrame(nFrameToAv);
    rangeImage(:,:,end+1) = frame.z;
    if (iEvent<=length(Z_delays))
        if useReset
            hw.runPresetScript('maReset');
        end
        if useManual
            hw.write('EXTLconLocDelayFastC', conLocDelayFastC(iEvent));
            hw.write('EXTLconLocDelayFastF', conLocDelayFastF(iEvent));
        end
        if useSyncLoop
            hw.setAlgoLoops(false, false);
            pause(1)
            hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 1 %s', dec2hex(conLocDelayFastC(iEvent))));
            hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 2 %s', dec2hex(conLocDelayFastF(iEvent))));
            hw.setAlgoLoops(true, false);
            pause(1)
        end
        if useShadow
            hw.shadowUpdate();
        end
        if useReset
            hw.runPresetScript('maRestart');
        end
    end
end

% Finalization
hw.stopStream();
filename = sprintf('dbg_rst%d_shd%d_man%d_sync%d_shup3b.mat', useReset, useShadow, useManual, useSyncLoop);
% filename = sprintf('dbg_rst%d_shd%d_man%d_sync%d_giantfix.mat', useReset, useShadow, useManual, useSyncLoop);
% filename = sprintf('dbg_rst%d_shd%d_man%d_sync%d_bigfix.mat', useReset, useShadow, useManual, useSyncLoop);
save(filename, 'delays', 'tmptrOffset', 'rangeImage', 'Z_delays')


%% Analysis

clims = [1000,1500]; % mm RTD
Z_delays_for_title = [98477, Z_delays];
figure
set(gcf, 'Position', [519, 383, 1143, 595])
for k = 1:length(Z_delays)+1
    subplot(2,3,k)
    imagesc(rot90(single(rangeImage(:,:,k))/4*2,2))
    title(sprintf('RTD capture #%d (Z delay = %d)', k, Z_delays_for_title(k)))
    colorbar
    set(gca,'clim',clims)
end
figure
set(gcf, 'Position', [519, 383, 1143, 595])
for k = 1:length(Z_delays)+1
    sortVals = sort(vec(single(rangeImage(:,:,k))/4*2));
    subplot(2,3,k)
    imagesc(rot90(single(rangeImage(:,:,k))/4*2,2))
    title(sprintf('RTD capture #%d (Z delay = %d)', k, Z_delays_for_title(k)))
    colorbar
    set(gca,'clim',[sortVals(round(0.1*numel(sortVals))),sortVals(round(0.9*numel(sortVals)))])
end