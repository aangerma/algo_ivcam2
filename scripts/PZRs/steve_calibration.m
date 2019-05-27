%% data loading
close all
clear variables
clc
tic

allData{1} = load('D:\Data\Ivcam2\PZR\captures_0404.mat');
allData{2} = load('D:\Data\Ivcam2\PZR\captures_0404x.mat');
allData{3} = load('D:\Data\Ivcam2\PZR\captures_0312.mat');


%% Common initializations
nSamplesInLog = 3116; % HARD CODED
steve_common_init
fs = 1e6; % HARD CODED
capturesOrder = [1,23,32,22,3,21,2,4,31,7,8,10,6,9,30,5,34,35,15,14,13,12,11,24,25,26,19,18,16,17,33,36,28,29,27,20,38,37,39,40,41];
lastInd = 0;

%% DSM-based linear model, single delay
for k = 1:1
% % stacking
% P = zeros(nSamples, 3);
% for iData = 1:length(allData)
%     for iLog = 1:length(allData{iData}.mclogs)
%         curMclog = allData{iData}.mclogs{iLog};
%         thetaH(lastInd+(1:nSamplesInLog)) = curMclog.actAngX';
%         thetaV(lastInd+(1:nSamplesInLog)) = curMclog.actAngY';
%         isExtrapolated(lastInd+(1:nSamplesInLog)) = curMclog.extrapolated';
%         P(lastInd+(1:nSamplesInLog), :) = [curMclog.angX', curMclog.angY', ones(nSamplesInLog,1)];
%         lastInd = lastInd + nSamplesInLog;
%     end
% end
% % for offset model, plant following lines in FitLinearModelWithDelay after estOutput (twice)
% % %%% degenerating linear model to a mere offset model
% % if mean(diff(delayedDesiredOutput))>1e-3 % y
% %     delayedError = delayedDesiredOutput-A(:,2); AA = A(:,3); optCoefs = (AA'*AA)\(AA'*delayedError); estOutput = AA*optCoefs+A(:,2);
% % else % x
% %     delayedError = delayedDesiredOutput-A(:,1); AA = A(:,3); optCoefs = (AA'*AA)\(AA'*delayedError); estOutput = AA*optCoefs+A(:,1);
% % end
% % % %%%
end

%% DSM-based quadratic model, single delay
for k = 1:1
% stacking
% allData = allData(1); steve_common_init
P = zeros(nSamples, 6);
% P = zeros(nSamples, 5);
for iData = 1:length(allData)
    for iLog = 1:length(allData{iData}.mclogs)
        curMclog = allData{iData}.mclogs{iLog};
        thetaH(lastInd+(1:nSamplesInLog)) = curMclog.actAngX';
        thetaV(lastInd+(1:nSamplesInLog)) = curMclog.actAngY';
        isExtrapolated(lastInd+(1:nSamplesInLog)) = curMclog.extrapolated';
        P(lastInd+(1:nSamplesInLog), :) = [curMclog.angX.^2', curMclog.angY.^2', curMclog.angX'.*curMclog.angY', curMclog.angX', curMclog.angY', ones(nSamplesInLog,1)];
%         P(lastInd+(1:nSamplesInLog), :) = [curMclog.angX.^2', curMclog.angY.^2', curMclog.angX', curMclog.angY', ones(nSamplesInLog,1)];
        lastInd = lastInd + nSamplesInLog;
    end
end
end

%% Linear model, single delay
for k = 1:1
% % stacking
% P = zeros(nSamples, 4);
% for iData = 1:length(allData)
%     for iLog = 1:length(allData{iData}.mclogs)
%         curMclog = allData{iData}.mclogs{iLog};
%         thetaH(lastInd+(1:nSamplesInLog)) = curMclog.actAngX';
%         thetaV(lastInd+(1:nSamplesInLog)) = curMclog.actAngY';
%         isExtrapolated(lastInd+(1:nSamplesInLog)) = curMclog.extrapolated';
%         P(lastInd+(1:nSamplesInLog), :) = [curMclog.PZR1', curMclog.PZR2', curMclog.PZR3', ones(nSamplesInLog,1)];
%         lastInd = lastInd + nSamplesInLog;
%     end
% end
end

%% quadratic model, single delay
for k = 1:1
% % stacking
% % allData = allData(1); steve_common_init
% % P = zeros(nSamples, 10); % full quadratic model
% P = zeros(nSamples, 7); % degenerated quadratic model
% for iData = 1:length(allData)
%     for iLog = 1:length(allData{iData}.mclogs)
%         curMclog = allData{iData}.mclogs{iLog};
%         thetaH(lastInd+(1:nSamplesInLog)) = curMclog.actAngX';
%         thetaV(lastInd+(1:nSamplesInLog)) = curMclog.actAngY';
%         isExtrapolated(lastInd+(1:nSamplesInLog)) = curMclog.extrapolated';
% %         P(lastInd+(1:nSamplesInLog), :) = [curMclog.PZR1.^2', curMclog.PZR2.^2', curMclog.PZR3.^2',...
% %                                            curMclog.PZR1'.*curMclog.PZR2', curMclog.PZR1'.*curMclog.PZR3', curMclog.PZR2'.*curMclog.PZR3',...
% %                                            curMclog.PZR1', curMclog.PZR2', curMclog.PZR3', ones(nSamplesInLog,1)];
%         P(lastInd+(1:nSamplesInLog), :) = [curMclog.PZR1.^2', curMclog.PZR2.^2', curMclog.PZR3.^2',...
%                                            curMclog.PZR1', curMclog.PZR2', curMclog.PZR3', ones(nSamplesInLog,1)];
%         lastInd = lastInd + nSamplesInLog;
%     end
% end
end

%% Calibration

% optimizing
if exist('lpFilter', 'var')
    extraDeadMargin = (length(lpFilter)-1)/2;
else
    %extraDeadMargin = 0;
    extraDeadMargin = 171;
end

delaysH = 170:1:180; % [samples] (coarse search for DSM)
% delaysH = -40:0.1:-20; % [samples] (coarse search around nominal delay)
% delaysH = -180:0.1:-170; % [samples] (coarse search outside nominal delay)
% delaysH = -32.5:0.01:-31.5; % [samples] (fine search around nominal delay)
% delaysH = -178.5:0.01:-176.5; % [samples] (fine search outside nominal delay)
isJointSupportH = (iSampleInLog>max(abs(delaysH))+extraDeadMargin & iSampleInLog<nSamplesInLog-max(abs(delaysH))-extraDeadMargin);
isRelevantForFitH = isJointSupportH & ~isExtrapolated;
[estThetaH, h, delayH, delayedThetaH, hStdVec] = FitLinearModelWithDelay(P, thetaH, delaysH, isRelevantForFitH);

delaysV = -10:1:10; % [samples] (coarse search for DSM)
% delaysV = -10:1:10; % [samples] (coarse search around nominal delay)
% delaysV = -155:1:-145; % [samples] (coarse search outside nominal delay)
% delaysV = -5.5:0.01:-4.5; % [samples] (fine search around nominal delay)
% delaysV = -150.5:0.01:-149.5; % [samples] (fine search outside nominal delay)
isJointSupportV = (iSampleInLog>max(abs(delaysV))+extraDeadMargin & iSampleInLog<nSamplesInLog-max(abs(delaysV))-extraDeadMargin);
isRelevantForFitV = isJointSupportV & ~isExtrapolated;
[estThetaV, v, delayV, delayedThetaV, vStdVec] = FitLinearModelWithDelay(P, thetaV, delaysV, isRelevantForFitV);

if false
    figure
    subplot(1,2,1), plot(delaysH/fs, hStdVec,'-o'), grid on, xlabel('delay [sec]'), ylabel('LS horizontal error STD [deg]'), title(sprintf('optimal delay = %.2f [usec]', delayH/fs/1e-6))
    subplot(1,2,2), plot(delaysV/fs, vStdVec,'-o'), grid on, xlabel('delay [sec]'), ylabel('LS vertical error STD [deg]'), title(sprintf('optimal delay = %.2f [usec]', delayV/fs/1e-6))
end

% evaluation
figure
subplot(1,2,1)
plot(delayedThetaH, estThetaH-delayedThetaH, '.', 'markersize', 2)
grid on, xlabel('actual angX [deg]'), ylabel('angX error [deg]')
title(sprintf('STD = %.3f[deg]', std(estThetaH-delayedThetaH)))
subplot(1,2,2)
plot(delayedThetaV, estThetaV-delayedThetaV, '.', 'markersize', 2)
grid on, xlabel('actual angY [deg]'), ylabel('angY error [deg]')
title(sprintf('STD = %.3f[deg]', std(estThetaV-delayedThetaV)))

% temporal examples for X
if false
    iLogs = 41;%1:41;
    figure, h1 = subplot(211); hold all, h2 = subplot(212); hold all, linkaxes([h1,h2],'x')
    for iLog = iLogs
        firstSampleInJointSupport = find(isJointSupportH, 1, 'first'); plotIdcs = find(iLogInData(isJointSupportH) == iLog);
        t = (firstSampleInJointSupport+plotIdcs-plotIdcs(1))/fs + (iLog-1)*nSamplesInLog/fs;
        subplot(211), plot(t, delayedThetaH(plotIdcs), '.-'), plot(t, estThetaH(plotIdcs), '.-')
        subplot(212), plot(t, estThetaH(plotIdcs)-delayedThetaH(plotIdcs), 'k.-')
    end
    subplot(211), grid on, xlim([iLogs(1)-1, iLogs(end)]*nSamplesInLog/fs), xlabel('time [sec]'), ylabel('angX [deg]'), legend('actual', 'estimated')
    subplot(212), grid on, xlim([iLogs(1)-1, iLogs(end)]*nSamplesInLog/fs), xlabel('time [sec]'), ylabel('angX error [deg]')
end

% temporal examples for Y
if false
    iLogs = 41;%1:41;
    figure, h1 = subplot(211); hold all, h2 = subplot(212); hold all, linkaxes([h1,h2],'x')
    for iLog = iLogs
        firstSampleInJointSupport = find(isJointSupportV, 1, 'first'); plotIdcs = find(iLogInData(isJointSupportV) == iLog);
        t = (firstSampleInJointSupport+plotIdcs-plotIdcs(1))/fs + (iLog-1)*nSamplesInLog/fs;
        subplot(211), plot(t, delayedThetaV(plotIdcs), '.-'), plot(t, estThetaV(plotIdcs), '.-')
        subplot(212), plot(t, estThetaV(plotIdcs)-delayedThetaV(plotIdcs), 'k.-')
    end
    subplot(211), grid on, xlim([iLogs(1)-1, iLogs(end)]*nSamplesInLog/fs), xlabel('time [sec]'), ylabel('angY [deg]'), legend('actual', 'estimated')
    subplot(212), grid on, xlim([iLogs(1)-1, iLogs(end)]*nSamplesInLog/fs), xlabel('time [sec]'), ylabel('angY error [deg]')
end

%%% LAST EFFORT
if false
    actV = delayedThetaV(plotIdcs); [actVf, actVa, actVp]=EstimateSineParams(actV',fs); actVsine = actVa*cos(2*pi*actVf*(t-t(1))+actVp);
    estV = estThetaV(plotIdcs);     [estVf, estVa, estVp]=EstimateSineParams(estV',fs); estVsine = estVa*cos(2*pi*estVf*(t-t(1))+estVp);
    subplot(211), plot(t, actVsine, 'g-'), plot(t, estVsine, 'y-'), vSine = (actVsine+estVsine)/2;
    figure, hold all, plot(t, actV-vSine, '.-'), plot(t, estV-vSine, '.-'), grid on, xlabel('time [sec]'), ylabel('distortion'), legend('actual','estimated')
    figure, hold all, plot(t, actV-vSine, '.-'), plot(t, circshift(estV-vSine,145), '.-'), grid on, xlabel('time [sec]'), ylabel('distortion'), legend('actual','estimated')
    figure, hold all, plot(t, estV-actV, '.-'), plot(t, circshift(estV-vSine,145)-(actV-vSine), '.-'), grid on, xlabel('time [sec]'), ylabel('distortion error'), legend('no additional delay', 'with 145usec delay')
end
%%%

% global plot
if false
    iLogs = 41;%1:41;
    figure
    hold all
    for iLog = iLogs
        firstSampleInJointSupport = find(isJointSupportH & isJointSupportV, 1, 'first');
        plotIdcs = find(iLogInData(isJointSupportH & isJointSupportV) == iLog);
        x = estThetaH(plotIdcs);
        plot(x, estThetaV(plotIdcs), '.-')
        grid on, xlabel('angX [sec]'), ylabel('angY [deg]')
    end
end
toc
