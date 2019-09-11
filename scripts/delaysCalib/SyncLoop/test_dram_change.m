%% EEPROM

T_ref = single(54.2363663);

EXTLconLocDelayFastC = uint32(98472);
EXTLconLocDelayFastF = uint32(5);
FRMWconLocDelayFastSlope = single(0.81);

EXTLconLocDelaySlow = uint32(2147483763);
FRMWconLocDelaySlowSlope = single(0.81); % 0.94

%% DRAM

T_ref = single(48.73);

EXTLconLocDelayFastC = uint32(98616);
EXTLconLocDelayFastF = uint32(3);
FRMWconLocDelayFastSlope = single(0.93);

EXTLconLocDelaySlow = uint32(2147483860);
FRMWconLocDelaySlowSlope = single(0.93); % 1.02

hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 1 %d', EXTLconLocDelayFastC))
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 2 %d', EXTLconLocDelayFastF))
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 3 %d', EXTLconLocDelaySlow))
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 4 %f', FRMWconLocDelayFastSlope))
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 5 %f', FRMWconLocDelaySlowSlope))
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 6 %f', T_ref))

%%

dt = (T_ref - Tldd);
fastCorrection = FRMWconLocDelayFastSlope*dt;
fastNew = single(EXTLconLocDelayFastC+EXTLconLocDelayFastF) + fastCorrection;
conLocDelayFastC = uint32(8*floor(fastNew/8));
conLocDelayFastF = uint32(mod(fastNew,8));
slowOrig = (EXTLconLocDelayFastC+EXTLconLocDelayFastF)-(EXTLconLocDelaySlow-uint32(2^31));
slowCorrection = FRMWconLocDelaySlowSlope*dt;
slowNew = single(slowOrig) + slowCorrection;
conLocDelaySlow = uint32(2^31)+uint32(fastNew)-uint32(slowNew);

delayIR = hw.read('EXTLconLocDelaySlow');
delayZC = hw.read('EXTLconLocDelayFastC');
delayZF = hw.read('EXTLconLocDelayFastF');

fprintf('Theory: slow=%d, fastC=%d, fastC=%d\n', conLocDelaySlow, conLocDelayFastC, conLocDelayFastF)
fprintf('Actual: slow=%d, fastC=%d, fastC=%d\n', delayIR, delayZC, delayZF)

