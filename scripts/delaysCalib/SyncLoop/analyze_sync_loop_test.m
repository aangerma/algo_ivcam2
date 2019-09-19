close all
clear variables
clc

v = 72;
plotTheoreticTrends = false;

%%

load(sprintf('sync_loop_test_results_v%d.mat',v))
if (v < 66)
    tmptrOffset = typecast(uint32(tmptrOffset),'single'); % for old results files
end

%%

% Data interpretation
C_MMnsec = 299.702547;
Z_delay = double(delays(:,2) + delays(:,3));
IR_delay = double((delays(:,2) + delays(:,3)) - (delays(:,1) - uint32(2^31)));
eeprom.modelIR = sprintf('%.2f*Tldd+%.2f', eeprom.IR_slope, eeprom.IR_offset);
eeprom.modelZ = sprintf('%.2f*Tldd+%.2f', eeprom.Z_slope, eeprom.Z_offset);
eeprom.modelRTD = sprintf('d(RTD)/dT = %.2f', -eeprom.Z_slope*C_MMnsec);
for k = 1:length(dram)
    dram(k).modelIR = sprintf('%.2f*Tldd+%.2f', dram(k).IR_slope, dram(k).IR_offset);
    dram(k).modelZ = sprintf('%.2f*Tldd+%.2f', dram(k).Z_slope, dram(k).Z_offset);
    dram(k).modelRTD = sprintf('d(RTD)/dT = %.2f', -dram(k).Z_slope*C_MMnsec);
end
uniqueSyncLoopSet = unique(syncLoopSet);

% Visualization
mrkrClrs = {[0,0,1], [1,0,0], [0,0.5,0]};
faceClrs = {[0.5,0.5,1], [1,0.5,0.5], [0,1,0]};
figure(1), hold on; leg1 = {};
figure(2), hold on; leg2 = {};
figure(3), hold on; leg3 = {};
for k = 1:length(uniqueSyncLoopSet)
    setIdcs = (syncLoopSet==uniqueSyncLoopSet(k));
    syncIdcs = setIdcs & (syncLoopEn==1);
    nonSyncIdcs = setIdcs & (syncLoopEn==0);
    % IR
    figure(1)
    h1(3*k-2) = plot(Tldd(nonSyncIdcs), IR_delay(nonSyncIdcs), '.', 'color', mrkrClrs{k});
    leg1{end+1} = sprintf('set %d, disabled', k);
    p = polyfit(Tldd(syncIdcs), IR_delay(syncIdcs), 1);
    h1(3*k-1) = plot(Tldd(syncIdcs), IR_delay(syncIdcs), 'o', 'color', mrkrClrs{k}, 'markerfacecolor', faceClrs{k});
    leg1{end+1} = sprintf('set %d, enabled', k);
    h1(3*k) = plot(Tldd(syncIdcs), p(1)*Tldd(syncIdcs)+p(2), '-', 'color', mrkrClrs{k});
    leg1{end+1} = sprintf('%.2f*Tldd+%.2f -> ',p(1),p(2));
    if plotTheoreticTrends
        if (k==1)
            plot(Tldd(syncIdcs), eeprom.IR_slope*Tldd(syncIdcs)+eeprom.IR_offset, 'k--')
        else
            plot(Tldd(syncIdcs), dram(k-1).IR_slope*Tldd(syncIdcs)+dram(k-1).IR_offset, 'k--')
        end
    end
    % Z
    figure(2)
    h2(3*k-2) = plot(Tldd(nonSyncIdcs), Z_delay(nonSyncIdcs), '.', 'color', mrkrClrs{k});
    leg2{end+1} = sprintf('set %d, disabled', k);
    p = polyfit(Tldd(syncIdcs), Z_delay(syncIdcs), 1);
    h2(3*k-1) = plot(Tldd(syncIdcs), Z_delay(syncIdcs), 'o', 'color', mrkrClrs{k}, 'markerfacecolor', faceClrs{k});
    leg2{end+1} = sprintf('set %d, enabled', k);
    h2(3*k) = plot(Tldd(syncIdcs), p(1)*Tldd(syncIdcs)+p(2), '-', 'color', mrkrClrs{k});
    leg2{end+1} = sprintf('%.2f*Tldd+%.2f -> ',p(1),p(2));
    if plotTheoreticTrends
        if (k==1)
            plot(Tldd(syncIdcs), eeprom.Z_slope*Tldd(syncIdcs)+eeprom.Z_offset, 'k--')
        else
            plot(Tldd(syncIdcs), dram(k-1).Z_slope*Tldd(syncIdcs)+dram(k-1).Z_offset, 'k--')
        end
    end
    % RTD compensation
    figure(3)
    h3(3*k-2) = plot(Tldd(nonSyncIdcs), tmptrOffset(nonSyncIdcs), '.', 'color', mrkrClrs{k});
    leg3{end+1} = sprintf('set %d, disabled', k);
    p = polyfit(Tldd(syncIdcs), tmptrOffset(syncIdcs), 1);
    h3(3*k-1) = plot(Tldd(syncIdcs), tmptrOffset(syncIdcs), 'o', 'color', mrkrClrs{k}, 'markerfacecolor', faceClrs{k});
    leg3{end+1} = sprintf('set %d, enabled', k);
    h3(3*k) = plot(Tldd(syncIdcs), p(1)*Tldd(syncIdcs)+p(2), '-', 'color', mrkrClrs{k});
    leg3{end+1} = sprintf('%.2f*Tldd+%.2f -> ',p(1),p(2));
end
iTL = find(thermalLoopEn==1,1,'first');
figure(1)
h1(end+1) = plot(mean(Tldd([iTL,iTL+1])), mean(IR_delay([iTL,iTL+1])), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg1{end+1} = 'Thermal Loop enable';
grid on, xlabel('Tldd [deg]'), ylabel('IR delay [nsec]'), legend(h1, leg1)
title(sprintf('Prior models:\n%s -> %s -> %s', eeprom.modelIR, dram(1).modelIR, dram(2).modelIR))
figure(2)
h2(end+1) = plot(mean(Tldd([iTL,iTL+1])), mean(Z_delay([iTL,iTL+1])), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg2{end+1} = 'Thermal Loop enable';
grid on, xlabel('Tldd [deg]'), ylabel('Z delay [nsec]'), legend(h2, leg2)
title(sprintf('Prior models:\n%s -> %s -> %s', eeprom.modelZ, dram(1).modelZ, dram(2).modelZ))
figure(3)
h3(end+1) = plot(mean(Tldd([iTL,iTL+1])), mean(tmptrOffset([iTL,iTL+1])), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg3{end+1} = 'Thermal Loop enable';
grid on, xlabel('Tldd'), ylabel('RTD thermal offset [mm]'), legend(h3, leg3)
title(sprintf('Prior models:\n%s -> %s -> %s', eeprom.modelRTD, dram(1).modelRTD, dram(2).modelRTD))
