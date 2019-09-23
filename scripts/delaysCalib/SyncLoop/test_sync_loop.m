close all
clear variables
clc


%% Sync Loop definitions

% Calibration info for F9280051
eeprom.IR_slope     = 0.94;
eeprom.IR_offset    = 98310.7;
eeprom.Z_slope      = 0.81;
eeprom.Z_offset     = 98432.9;
eeprom.T_ref        = 54.2363663;

% Desired DRAM changes
dram(1).IR_slope    = 1.19;
dram(1).IR_offset   = 97765.4;
dram(1).Z_slope     = 0.93;
dram(1).Z_offset    = 98142.1;
dram(1).T_ref       = 47.3;

dram(2).IR_slope    = 0.83;
dram(2).IR_offset   = 98703.5;
dram(2).Z_slope     = 1.05;
dram(2).Z_offset    = 98739.8;
dram(2).T_ref       = 52.1;


%% Sync Loop preprocessing

eeprom.IR_delay                = round(eeprom.IR_offset + eeprom.IR_slope*eeprom.T_ref);
eeprom.Z_delay                 = round(eeprom.Z_offset + eeprom.Z_slope*eeprom.T_ref);
eeprom.conLocDelayFastC        = uint32(8*floor(eeprom.Z_delay/8));
eeprom.conLocDelayFastF        = uint32(mod(eeprom.Z_delay,8));
eeprom.conLocDelaySlow         = uint32(2^31)+(uint32(eeprom.Z_delay)-uint32(eeprom.IR_delay));
for k = 1:length(dram)
    dram(k).IR_delay                = round(dram(k).IR_offset + dram(k).IR_slope*dram(k).T_ref);
    dram(k).Z_delay                 = round(dram(k).Z_offset + dram(k).Z_slope*dram(k).T_ref);
    dram(k).conLocDelayFastC        = uint32(8*floor(dram(k).Z_delay/8));
    dram(k).conLocDelayFastF        = uint32(mod(dram(k).Z_delay,8));
    dram(k).conLocDelaySlow         = uint32(2^31)+(uint32(dram(k).Z_delay)-uint32(dram(k).IR_delay));
    dram(k).setParamCmds    = {dec2hex(dram(k).conLocDelayFastC), dec2hex(dram(k).conLocDelayFastF), dec2hex(dram(k).conLocDelaySlow),...
        cell2mat(single2hex(dram(k).Z_slope)), cell2mat(single2hex(dram(k).IR_slope)), cell2mat(single2hex(dram(k).T_ref))};
end


%% Timeline

% Definitions
testDuration = 35*60; % [sec] (=2100)
samplingTime = 5; % [sec]
% 5[min] with EEPROM vals, 10[min] after 1st change, 20[min] after 2nd change
eventDefinitions = {30,       'enableSL',   {};
                    30+100,   'disableSL',  {};...
                    130+60,   'enableSL',   {};...
                    190+100,  'disableSL',  {};...
                    290+10,   'dramChange', dram(1).setParamCmds;...
                    300+50,   'enableSL',   {};...
                    350+200,  'disableSL',  {};...
                    550+100,  'enableTL',   {};...
                    550+120,  'enableSL',   {};...
                    670+200,  'disableSL',  {};...
                    870+30,   'dramChange', dram(2).setParamCmds;...
                    900+80,   'enableSL',   {};...
                    980+400,  'disableSL',  {};...
                    1380+240, 'enableSL',   {};...
                    1620+400, 'disableSL',  {}};
% eventDefinitions = {10,       'enableSL',   {};
%                     20,   'disableSL',  {};...
%                     30,   'enableSL',   {};...
%                     40,  'disableSL',  {};...
%                     50,   'dramChange', dram(1).setParamCmds;...
%                     60,   'enableSL',   {};...
%                     70,  'disableSL',  {};...
%                     80,  'enableTL',   {};...
%                     90,  'enableSL',   {};...
%                     100,  'disableSL',  {};...
%                     110,   'dramChange', dram(2).setParamCmds;...
%                     120,   'enableSL',   {};...
%                     130,  'disableSL',  {};...
%                     2140, 'enableSL',   {};...
%                     150, 'disableSL',  {}};
events = struct('time', 0, 'type', '', 'params', {});
for iEvent = 1:size(eventDefinitions,1)
    events(iEvent).time     = eventDefinitions{iEvent,1};
    events(iEvent).type     = eventDefinitions{iEvent,2};
    events(iEvent).params   = eventDefinitions{iEvent,3};
end

% Initializations
Tldd            = zeros(0,1);
delays          = zeros(0,3,'uint32');
syncLoopEn      = zeros(0,1);
syncLoopSet     = zeros(0,1);
tmptrOffset     = zeros(0,1);
thermalLoopEn   = zeros(0,1);
zMidMeanMedStd  = zeros(0,4,'uint16');
futureEvents    = events;


%% Actual test

res = [480,640]; % VGA
nFrameToAv = 30;

% Initializations
hw = HWinterface();
hw.cmd('dirtybitbypass');
tlState = hw.cmd('GET_ALGO_THERMAL_LOOP');
if strcmp(tlState(1:end-1), 'AlgoThermalLoopEnable:   TRUE')
    fprintf('Camera woke up with thermal loop enabled - OK.\n')
else
    fprintf('Warning: camera woke up with thermal loop disabled.\n')
end
slState = hw.cmd('GET_SYNC_LOOP');
if strcmp(slState(1:end-1), 'SyncLoopEnable:   TRUE')
    fprintf('Camera woke up with sync loop enabled - OK.\n')
else
    fprintf('Warning: camera woke up with sync loop disabled.\n')
end
hw.cmd('ENABLE_SYNC_LOOP 0');
hw.disableAlgoThermalLoop();
% hw.cmd('mwd a00e0894 a00e0898 00000001')
hw.startStream(0,res);

t0                  = tic;
t                   = toc(t0);
curSyncLoopEn       = 0;
curSyncLoopSet      = 0;
curThermalLoopEn    = 0;

while (t < testDuration)
    t = toc(t0);
    
    % Unit state reading
    Tldd(end+1,1)           = hw.getLddTemperature;
    delayIR                 = hw.read('EXTLconLocDelaySlow');
    delayZC                 = hw.read('EXTLconLocDelayFastC');
    delayZF                 = hw.read('EXTLconLocDelayFastF');
    delays(end+1,:)         = [delayIR, delayZC, delayZF];
    syncLoopEn(end+1,1)     = curSyncLoopEn;
    syncLoopSet(end+1,1)    = curSyncLoopSet;
    tmptrOffset(end+1,1)    = typecast(hw.read('DESTtmptrOffset'), 'single');
    thermalLoopEn(end+1)    = curThermalLoopEn;
    % Event realization
    if ~isempty(futureEvents) && (t >= futureEvents(1).time)
        fprintf('t = %.1f[min] , T = %.1f , delays = [%d, %d, %d], initiating %s event\n', t/60, Tldd(end), delayIR, delayZC, delayZF, futureEvents(1).type)
        switch futureEvents(1).type
            case 'enableSL'
                hw.cmd('ENABLE_SYNC_LOOP 1');
                curSyncLoopEn = 1;
            case 'disableSL'
                hw.cmd('ENABLE_SYNC_LOOP 0');
                curSyncLoopEn = 0;
            case 'enableTL'
                hw.enableAlgoThermalLoop();
                curThermalLoopEn = 1;
            case 'dramChange'
                for iCmd = 1:6
                    hw.cmd(sprintf('SET_PARAM_SYNC_LOOP %d %s', iCmd, futureEvents(1).params{iCmd}));
                end
                curSyncLoopSet = curSyncLoopSet+1;
            otherwise
                error('unknown event type')
        end
        futureEvents = futureEvents(2:end);
    end
    frame = hw.getFrame(nFrameToAv);
    zValues = frame.z(:);
    zMidMeanMedStd(end+1,:) = [frame.z(res(1)/2,res(2)/2), uint16(mean(zValues)), median(zValues), uint16(std(single(zValues)))];
    pause(samplingTime)
end

% Finalization
hw.stopStream();
save('sync_loop_test_results.mat', 'eeprom', 'dram', 'events', 'Tldd', 'delays', 'syncLoopEn', 'syncLoopSet', 'tmptrOffset', 'thermalLoopEn', 'zMidMeanMedStd')

