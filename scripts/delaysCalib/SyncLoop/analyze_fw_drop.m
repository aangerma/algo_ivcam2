close all
clear variables
clc

%%

% load('test_results.mat')
load('test_results_drop59.mat')
Z_delay = delays(:,2) + delays(:,3);
IR_delay = Z_delay - (delays(:,1)-2^31);

iStartSL = find(diff([syncLoopEn;0])==1);
iEndSL = find(diff([syncLoopEn;0])==-1);

%%

figure

subplot(121)
hold on
h = plot(Tldd, IR_delay, 'o');
p = polyfit(Tldd(syncLoopEn==1), IR_delay(syncLoopEn==1), 1);
plot(Tldd, p(1)*Tldd+p(2), '-', 'color', get(h,'color'))
irmin = min(IR_delay);
irmax = max(IR_delay);
for iSL = 1:length(iStartSL)
    patch(Tldd([iStartSL(iSL), iStartSL(iSL), iEndSL(iSL), iEndSL(iSL), iStartSL(iSL)]), [irmin, irmax, irmax, irmin, irmin], 'y', 'facealpha', 0.15)
end
grid on, xlabel('Tldd [deg]'), ylabel('IR delay [nsec]')
title(sprintf('IR delay = %.3f*T_L_D_D + %.3f', p(1), p(2)))

subplot(122)
hold on
h = plot(Tldd, Z_delay, 'o');
p = polyfit(Tldd(syncLoopEn==1), Z_delay(syncLoopEn==1), 1);
plot(Tldd, p(1)*Tldd+p(2), '-', 'color', get(h,'color'))
zmin = min(Z_delay);
zmax = max(Z_delay);
for iSL = 1:length(iStartSL)
    patch(Tldd([iStartSL(iSL), iStartSL(iSL), iEndSL(iSL), iEndSL(iSL), iStartSL(iSL)]), [zmin, zmax, zmax, zmin, zmin], 'y', 'facealpha', 0.15)
end
grid on, xlabel('Tldd [deg]'), ylabel('Z delay [nsec]')
title(sprintf('Z delay = %.3f*T_L_D_D + %.3f', p(1), p(2)))
