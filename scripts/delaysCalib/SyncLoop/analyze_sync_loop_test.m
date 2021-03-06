close all
clear variables
clc

v = 75;
plotTheoreticTrends = false;

%%

load(sprintf('sync_loop_test_results_v%d.mat',v))
if (v < 66)
    tmptrOffset = typecast(uint32(tmptrOffset),'single'); % for old results files
end

%%

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
    leg1{end+1} = sprintf('%.2f*Tldd+%.2f',p(1),p(2));
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
    leg2{end+1} = sprintf('%.2f*Tldd+%.2f',p(1),p(2));
    if plotTheoreticTrends
        if (k==1)
            plot(Tldd(syncIdcs), eeprom.Z_slope*Tldd(syncIdcs)+eeprom.Z_offset, 'k--')
        else
            plot(Tldd(syncIdcs), dram(k-1).Z_slope*Tldd(syncIdcs)+dram(k-1).Z_offset, 'k--')
        end
    end
    % RTD compensation
    figure(3)
    h3(2*k-1) = plot(Tldd(nonSyncIdcs), tmptrOffset(nonSyncIdcs), '.', 'color', mrkrClrs{k});
    leg3{end+1} = sprintf('set %d, disabled', k);
    h3(2*k) = plot(Tldd(syncIdcs), tmptrOffset(syncIdcs), 'o', 'color', mrkrClrs{k}, 'markerfacecolor', faceClrs{k});
    leg3{end+1} = sprintf('set %d, enabled', k);
end
p = polyfit(Tldd(thermalLoopEn==1), tmptrOffset(thermalLoopEn==1), 1);
h3(end+1) = plot(Tldd(thermalLoopEn==1), p(1)*Tldd(thermalLoopEn==1)+p(2), 'k-');
leg3{end+1} = sprintf('%.2f*Tldd+%.2f',p(1),p(2));

iTL = find(thermalLoopEn==1,1,'first');
figure(1)
h1(end+1) = plot(Tldd(iTL), IR_delay(iTL), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg1{end+1} = 'Thermal Loop enable';
grid on, xlabel('Tldd [deg]'), ylabel('IR delay [nsec]'), legend(h1, leg1)
title(sprintf('Prior models:\n%s -> %s -> %s', eeprom.modelIR, dram(1).modelIR, dram(2).modelIR))
figure(2)
h2(end+1) = plot(Tldd(iTL), Z_delay(iTL), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg2{end+1} = 'Thermal Loop enable';
grid on, xlabel('Tldd [deg]'), ylabel('Z delay [nsec]'), legend(h2, leg2)
title(sprintf('Prior models:\n%s -> %s -> %s', eeprom.modelZ, dram(1).modelZ, dram(2).modelZ))
figure(3)
h3(end+1) = plot(Tldd(iTL), tmptrOffset(iTL), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg3{end+1} = 'Thermal Loop enable';
grid on, xlabel('Tldd'), ylabel('RTD thermal offset [mm]'), legend(h3, leg3)
title('DESTtmptrOffset')

rtd = single(depths)/4*2; % [center pixels, median]
figure(4)
hold all
p = polyfit(Tldd(thermalLoopEn==0), rtd(thermalLoopEn==0,1), 1);
h4(1) = plot(Tldd, rtd(:,1), 'o', 'color', mrkrClrs{1});
leg4{1} = 'mean over 30 frames';
h4(2) = plot(Tldd(thermalLoopEn==0), p(1)*Tldd(thermalLoopEn==0)+p(2), '-', 'color', mrkrClrs{1}, 'linewidth', 2);
leg4{2} = sprintf('%.2f*Tldd+%.2f',p(1),p(2));
h4(3) = plot(Tldd(iTL), rtd(iTL,1), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg4{3} = 'Thermal Loop enable';
% p = polyfit(Tldd(thermalLoopEn==0), rtd(thermalLoopEn==0,2), 1);
% h4(3) = plot(Tldd, rtd(:,2), 'o', 'color', mrkrClrs{2});
% leg4{3} = 'median';
% h4(4) = plot(Tldd(thermalLoopEn==0), p(1)*Tldd(thermalLoopEn==0)+p(2), '-', 'color', mrkrClrs{2});
% leg4{4} = sprintf('%.2f*Tldd+%.2f',p(1),p(2));
% h4(5) = plot(Tldd(iTL)*ones(1,2), rtd(iTL,:), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
% leg4{5} = 'Thermal Loop enable';
grid on, xlabel('Tldd [deg]'), ylabel('RTD [mm]'), legend(h4, leg4)
title('RTD @ center pixel')
