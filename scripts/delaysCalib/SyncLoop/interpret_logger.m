close all
clear variables
clc

%%

fid = fopen('X:\Users\syaeli\Work\Code\algo_ivcam2\scripts\delaysCalib\SyncLoop\logger_sync_loop4.txt', 'rt');
data = cell(0,1);
while true
    y = fgetl(fid);
    if (y==-1)
        break
    end
    data{end+1,1} = y;
end

%%

syncLoopStr = 'Algo Thermal Loop';
msgStartInd = 155;
for k = 1:length(data)
    if (length(data{k}) >= msgStartInd+length(syncLoopStr)) && strcmp(data{k}(msgStartInd:msgStartInd+length(syncLoopStr)-1), syncLoopStr)
        atlData{k} = data{k}(msgStartInd:end);
    else
        atlData{k} = [];
    end
end
atlData = atlData(cellfun(@(t) ~isempty(t),atlData));
codeAndValue = zeros(length(atlData),3);
for k = 1:length(atlData)
    codeAndValue(k,:) = sscanf(atlData{k}, 'Algo Thermal Loop - Temperature\\Delay = %d, %d, %f');
end
code = reshape(codeAndValue(:,1), 10, []);
value = reshape(codeAndValue(:,3), 10, []);
code = rot90(code,2);
value = rot90(value,2);

%%

names = {'tempCelcius', 'DelayFastCorrection', 'DelayFastNew', 'DelaySlowOrig', 'DelaySlowCorrection', 'DelaySlowNew',...
    'ASIC_conLocDelayFastC', 'ASIC_conLocDelayFastF', '(ASIC_conLocDelaySlow - (1<<31))', 'syncCompensation'};
codes = [1,2,3,4,5,6,11,12,13,20];

%%

iEvent = 1; % 1, 70, 140

tmp = [code(:, iEvent), value(:, iEvent)];
for k = 1:size(tmp,1)
    iName = find(codes==tmp(k,1));
    fprintf('%s = %f\n', names{iName}, tmp(k,2))
end

%%

dfc_th = 0.81*(value(1, :) - 54.2363663);
dfc_act = value(2, :);
figure, hold on, plot(dfc_th,'-o'), plot(dfc_act,'-^'), grid on, legend('theroretic','actual')
