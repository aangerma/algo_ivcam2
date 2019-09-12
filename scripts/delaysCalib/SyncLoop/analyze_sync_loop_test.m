close all
clear variables
clc

load('sync_loop_test_results.mat')

% Data interpretation
Z_delay = double(delays(:,2) + delays(:,3));
IR_delay = double((delays(:,2) + delays(:,3)) - (delays(:,1) - uint32(2^31)));
eeprom.modelIR = sprintf('%.2f*Tldd+%.2f', eeprom.IR_slope, eeprom.IR_offset);
eeprom.modelZ = sprintf('%.2f*Tldd+%.2f', eeprom.Z_slope, eeprom.Z_offset);
for k = 1:length(dram)
    dram(k).modelIR = sprintf('%.2f*Tldd+%.2f', dram(k).IR_slope, dram(k).IR_offset);
    dram(k).modelZ = sprintf('%.2f*Tldd+%.2f', dram(k).Z_slope, dram(k).Z_offset);
end
uniqueSyncLoopSet = unique(syncLoopSet);

% Delays visualization
mrkrClrs = {[0,0,1], [1,0,0], [0,0.5,0]};
faceClrs = {[0.5,0.5,1], [1,0.5,0.5], [0,1,0]};
figure(1), hold on; leg1 = {};
figure(2), hold on; leg2 = {};
for k = 1:length(uniqueSyncLoopSet)
    setIdcs = (syncLoopSet==uniqueSyncLoopSet(k));
    syncIdcs = setIdcs & (syncLoopEn==1);
    nonSyncIdcs = setIdcs & (syncLoopEn==0);
    % IR
    figure(1)
    h1(3*k-2) = plot(Tldd(nonSyncIdcs), IR_delay(nonSyncIdcs), 'o', 'color', mrkrClrs{k});
    leg1{end+1} = sprintf('set %d, disabled', k);
    p = polyfit(Tldd(syncIdcs), IR_delay(syncIdcs), 1);
    h1(3*k-1) = plot(Tldd(syncIdcs), IR_delay(syncIdcs), 'o', 'color', mrkrClrs{k}, 'markerfacecolor', faceClrs{k});
    leg1{end+1} = sprintf('set %d, enabled', k);
    h1(3*k) = plot(Tldd(syncIdcs), p(1)*Tldd(syncIdcs)+p(2), '-', 'color', mrkrClrs{k});
    leg1{end+1} = sprintf('%.2f*Tldd+%.2f -> ',p(1),p(2));
    % Z
    figure(2)
    h2(3*k-2) = plot(Tldd(nonSyncIdcs), Z_delay(nonSyncIdcs), 'o', 'color', mrkrClrs{k});
    leg2{end+1} = sprintf('set %d, disabled', k);
    p = polyfit(Tldd(syncIdcs), Z_delay(syncIdcs), 1);
    h2(3*k-1) = plot(Tldd(syncIdcs), Z_delay(syncIdcs), 'o', 'color', mrkrClrs{k}, 'markerfacecolor', faceClrs{k});
    leg2{end+1} = sprintf('set %d, enabled', k);
    h2(3*k) = plot(Tldd(syncIdcs), p(1)*Tldd(syncIdcs)+p(2), '-', 'color', mrkrClrs{k});
    leg2{end+1} = sprintf('%.2f*Tldd+%.2f -> ',p(1),p(2));
end
figure(1)
grid on, xlabel('Tldd [deg]'), ylabel('IR delay [nsec]'), legend(h1, leg1)
title(sprintf('Prior models:\n%s -> %s -> %s', eeprom.modelIR, dram(1).modelIR, dram(2).modelIR))
figure(2)
grid on, xlabel('Tldd [deg]'), ylabel('Z delay [nsec]'), legend(h2, leg2)
title(sprintf('Prior models:\n%s -> %s -> %s', eeprom.modelZ, dram(1).modelZ, dram(2).modelZ))

% RTD compensation visualization
figure(3), hold on
plot(Tldd(thermalLoopEn==0), tmptrOffset(thermalLoopEn==0), 'ko')
plot(Tldd(thermalLoopEn==1), tmptrOffset(thermalLoopEn==1), 'ko', 'markerfacecolor', [0.5,0.5,0.5])
p = polyfit(Tldd(thermalLoopEn==1), tmptrOffset(thermalLoopEn==1), 1);
plot(Tldd(thermalLoopEn==1), p(1)*Tldd(thermalLoopEn==1)+p(2), 'k-')
grid on, xlabel('Tldd'), ylabel('RTD thermal offset [mm]')
legend('thermal loop disabled', 'thermal loop enabled', sprintf('%.2f*Tldd+%.2f -> ',p(1),p(2)))
