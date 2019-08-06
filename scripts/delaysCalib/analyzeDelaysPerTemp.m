clear variables
clc

%%

%files = [dir('Results\F92*.mat'); dir('Results\F91*.mat')];
files = dir('Results\F92*.mat');
for iFile = 1:length(files)
    data(iFile) = load(['Results\', files(iFile).name]);
    serialNum{iFile} = files(iFile).name(1:8);
end

%%

tempsAx = 32:79;

figure(1)
subplot(121)
hold all
irLeg = serialNum;
for iFile = 1:length(files)
    h(iFile) = plot(data(iFile).temps, data(iFile).delays(:,1), 'o');
end
for iFile = 1:length(files)
    irLinCoefs = polyfit(data(iFile).temps, data(iFile).delays(:,1), 1);
    irFit = irLinCoefs(1)*tempsAx + irLinCoefs(2);
    plot(tempsAx, irFit, '-', 'color', get(h(iFile), 'color'))
    irLeg{end+1} = sprintf('%.1f+%.2ft', irLinCoefs(2), irLinCoefs(1));
end
grid on, xlabel('LDD temperature [deg]'), ylabel('IR delay [nsec]'), axis equal
legend(irLeg)

subplot(122)
hold all
zLeg = serialNum;
for iFile = 1:length(files)
    plot(data(iFile).temps, data(iFile).delays(:,2), 'o', 'color', get(h(iFile), 'color'))
end
for iFile = 1:length(files)
    zLinCoefs = polyfit(data(iFile).temps, data(iFile).delays(:,2), 1);
    zFit = zLinCoefs(1)*tempsAx + zLinCoefs(2);
    plot(tempsAx, zFit, '-', 'color', get(h(iFile), 'color'))
    zLeg{end+1} = sprintf('%.1f+%.2ft', zLinCoefs(2), zLinCoefs(1));
end
grid on, xlabel('LDD temperature [deg]'), ylabel('Z delay [nsec]'), axis equal
legend(zLeg)
