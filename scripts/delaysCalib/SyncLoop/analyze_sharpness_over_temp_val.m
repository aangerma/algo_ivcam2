close all
clear all
clc

%%
% results on F9280140 with 1.3.4.231

noSL = load('sharpness_results_SL0.mat');
noSL.hTransMean = cellfun(@(x) mean(x(:)), noSL.hTrans);
noSL.delayFast = noSL.delayRegs(:,2) + noSL.delayRegs(:,3);
noSL.delaySlow = noSL.delayFast - (noSL.delayRegs(:,1)-uint32(2^31));
i46 = find(noSL.Tldd>46,1,'first');
p = polyfit(noSL.Tldd(1:i46), noSL.hTransMean(1:i46), 1);
withSL = load('sharpness_results_SL1.mat');
withSL.hTransMean = cellfun(@(x) mean(x(:)), withSL.hTrans);
withSL.delayFast = withSL.delayRegs(:,2) + withSL.delayRegs(:,3);
withSL.delaySlow = withSL.delayFast - (withSL.delayRegs(:,1)-uint32(2^31));

Tref = 51.6909;

%%

figure
hold all
h(1) = plot(withSL.Tldd, withSL.hTransMean, 'o');
h(2) = plot(noSL.Tldd, noSL.hTransMean, 'o');
h(3) = plot(20:46, p(1)*(20:46)+p(2), '-', 'color', get(h(2),'color'));
h(4) = plot(Tref, interp1(noSL.Tldd, noSL.hTransMean, Tref), 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg = {'with sync loop', 'without sync loop', sprintf('%.2f*Tldd+%.2f',p(1),p(2)), 'reference temperature'};
grid on, xlabel('temperature [deg]'), ylabel('mean vertical sharpness [pixels]'), legend(h, leg)

%%

figure
hold all
cdfplot(withSL.hTrans{1}(:))
cdfplot(noSL.hTrans{1}(:))
leg = {sprintf('with sync loop @ %.1f[deg]', withSL.Tldd(1)), sprintf('without sync loop @ %.1f[deg]', noSL.Tldd(1))};
grid on, xlabel('vertical sharpness [pixels]'), ylabel('CDF'), legend(leg)

%%

figure
subplot(211)
hold all
plot(withSL.Tldd, withSL.delaySlow, '-o')
grid on, xlabel('temperature [deg]'), ylabel('slow channel delay [nsec]')
subplot(212)
hold all
plot(withSL.Tldd, withSL.delayFast, '-o')
grid on, xlabel('temperature [deg]'), ylabel('fast channel delay [nsec]')


