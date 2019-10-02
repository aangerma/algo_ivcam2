close all
clear all
clc

%%

noSL = load('sharpness_results_SL0_VGA.mat');
noSL.hTransMean = cellfun(@(x) mean(x(:)), noSL.hTrans);
i46 = find(noSL.Tldd>46,1,'first');
p = polyfit(noSL.Tldd(1:i46), noSL.hTransMean(1:i46), 1);
withSL = load('sharpness_results_SL1_VGA.mat');
withSL.hTransMean = cellfun(@(x) mean(x(:)), withSL.hTrans);

Tref = 54.2363663;

%%

figure
hold all
h(1) = plot(withSL.Tldd, withSL.hTransMean, 'o');
h(2) = plot(noSL.Tldd, noSL.hTransMean, 'o');
h(3) = plot(10:46, p(1)*(10:46)+p(2), '-', 'color', get(h(2),'color'));
h(4) = plot(Tref, 2.2, 'p', 'color', [0.5,0.5,0], 'markerfacecolor', 'y', 'markersize', 10);
leg = {'with sync loop', 'without sync loop', sprintf('%.2f*Tldd+%.2f',p(1),p(2)), 'reference temperature'};
grid on, xlabel('temperature [deg]'), ylabel('vertical sharpness [pixels]'), legend(h, leg)

%%

figure
hold all
cdfplot(withSL.hTrans{1}(:))
cdfplot(noSL.hTrans{1}(:))
leg = {sprintf('with sync loop @ %.1f[deg]', withSL.Tldd(1)), sprintf('without sync loop @ %.1f[deg]', noSL.Tldd(1))};
grid on, xlabel('vertical sharpness [pixels]'), ylabel('CDF'), legend(leg)



