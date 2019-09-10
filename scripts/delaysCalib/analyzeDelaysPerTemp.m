clear variables
clc

%%

baseDir = 'Results\';
% baseDir = '';
files = [dir('Results\F928*.mat'); dir('Results\F924*.mat'); dir('Results\F91*.mat'); dir('Results\F922*.mat')];
% files = dir([baseDir, 'F922*.mat']);
withBiases = false;

%%

for iFile = 1:length(files)
    loadedData = load([baseDir, files(iFile).name]);
    if ~isfield(loadedData,'biases')
        loadedData.biases = NaN(size(loadedData.temps));
    end
    data(iFile) = loadedData;
    serialNum{iFile} = files(iFile).name(1:8);
end
if withBiases
    idcsToKeep = arrayfun(@(x) all(~isnan(x.biases)), data);
    data = data(idcsToKeep);
    serialNum = serialNum(idcsToKeep); 
else
    data = rmfield(data, 'biases');
end

%%

fnames = fieldnames(data(iFile));
iFile = find(strcmp(serialNum,'F9220005'));
for iField = 1:length(fnames)
    data(iFile).(fnames{iField}) = data(iFile).(fnames{iField})(1:7,:);
end
iFile = find(strcmp(serialNum,'F9220056'));
for iField = 1:length(fnames)
    data(iFile).(fnames{iField}) = data(iFile).(fnames{iField})([1:2,4:7],:);
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

if withBiases
    biasesAx = 2:0.1:2.5;
    
    figure(2)
    subplot(121)
    hold all
    irLeg = serialNum;
    for iFile = 1:length(files)
        h(iFile) = plot(data(iFile).biases, data(iFile).delays(:,1), 'o');
    end
    for iFile = 1:length(files)
        irLinCoefs = polyfit(data(iFile).biases, data(iFile).delays(:,1), 1);
        irFit = irLinCoefs(1)*biasesAx + irLinCoefs(2);
        plot(biasesAx, irFit, '-', 'color', get(h(iFile), 'color'))
        irLeg{end+1} = sprintf('%.1f+%.2ft', irLinCoefs(2), irLinCoefs(1));
    end
    grid on, xlabel('vBias2 [V]'), ylabel('IR delay [nsec]')
    legend(irLeg)
    
    subplot(122)
    hold all
    zLeg = serialNum;
    for iFile = 1:length(files)
        plot(data(iFile).biases, data(iFile).delays(:,2), 'o', 'color', get(h(iFile), 'color'))
    end
    for iFile = 1:length(files)
        zLinCoefs = polyfit(data(iFile).biases, data(iFile).delays(:,2), 1);
        zFit = zLinCoefs(1)*biasesAx + zLinCoefs(2);
        plot(biasesAx, zFit, '-', 'color', get(h(iFile), 'color'))
        zLeg{end+1} = sprintf('%.1f+%.2ft', zLinCoefs(2), zLinCoefs(1));
    end
    grid on, xlabel('vBias2 [V]'), ylabel('Z delay [nsec]')
    legend(zLeg)
end
