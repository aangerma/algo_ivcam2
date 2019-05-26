%% data loading

close all
clear variables
clc

% load('D:\Data\Ivcam2\PZR\captures_0312.mat')
load('D:\Data\Ivcam2\PZR\captures_0404.mat')
% load('D:\Data\Ivcam2\PZR\captures_0404x.mat')


%% actual Y single frame analysis
for k = 1:1
% basic plot
% fs = 1e6;
% n = length(mclog.actAngY);
% t = (0:n-1)/fs;
% figure(1), hold on, plot(t, mclog.actAngY, 'b'), grid on, xlabel('t [sec]'), ylabel('actual angY [deg]')
% 
% % envelope detection
% [maxVals, maxIdcs] = findpeaks(mclog.actAngY);
% maxLinCoefs = polyfit(t(maxIdcs), maxVals, 1);
% plot(t, maxLinCoefs(1)*t + maxLinCoefs(2), 'k--', 'linewidth', 2)
% 
% [minVals, minIdcs] = findpeaks(-mclog.actAngY);
% minLinCoefs = polyfit(t(minIdcs), -minVals, 1);
% plot(t, minLinCoefs(1)*t + minLinCoefs(2), 'k--', 'linewidth', 2)
% 
% driftCoefs = (maxLinCoefs+minLinCoefs)/2;
% drift = driftCoefs(1)*t + driftCoefs(2);
% plot(t, drift, 'k--')
% amp = (maxLinCoefs(1)-minLinCoefs(1))/2*t + (maxLinCoefs(2)-minLinCoefs(2))/2;
% ampChange = 100*(amp(end)-amp(1))/amp(1);
% title(sprintf('Drift: %.2f + %.2f*t ; Amp change: %.1f%%', driftCoefs(2), driftCoefs(1), ampChange))
% 
% % spectral analysis
% paddingRatio = 100;
% F = fft([mclog.actAngY, zeros(1,(paddingRatio-1)*n)]); F = fftshift(F/max(abs(F)));
% f = (0:paddingRatio*n-1)/(paddingRatio*n)*fs; f(f>=fs/2) = f(f>=fs/2)-fs; f = fftshift(f);
% figure(2), hold on, plot(f, mag2db(abs(F)), 'b'), grid on, xlabel('freq [Hz]'), ylabel('actual angY spectrum [dB]')
% 
% [~, maxInd] = max(abs(F).*sign(f));
% interpIdcs = maxInd + (-5:5);
% warning('off', 'MATLAB:polyfit:RepeatedPointsOrRescale')
% freqSqrCoefs = polyfit(f(interpIdcs), abs(F(interpIdcs)), 2);
% warning('on', 'MATLAB:polyfit:RepeatedPointsOrRescale')
% fInt = linspace(f(interpIdcs(1)), f(interpIdcs(end)), 100);
% plot(fInt, mag2db(freqSqrCoefs * [fInt.^2; fInt; ones(size(fInt))]), 'k--', 'linewidth', 2)
% fRes = -freqSqrCoefs(2)/(2*freqSqrCoefs(1));
% plot(fRes, mag2db(freqSqrCoefs(1)*fRes.^2 + freqSqrCoefs(2)*fRes + freqSqrCoefs(3)), 'ko')
% title(sprintf('Resonance freq: %.2fHz', fRes))
% 
% for k = -10:2:10, plot(-fRes + 20e3*k*ones(1,2), [-100,0], 'g-'), end
% for k = -10:2:10, plot(fRes + 20e3*k*ones(1,2), [-100,0], 'g-'), end
end

%% actual X single frame analysis
for k = 1:1
% % basic plot
% fs = 1e6;
% n = length(mclog.actAngX);
% t = (0:n-1)/fs;
% figure(3), hold on, plot(t, mclog.actAngX, 'b'), grid on, xlabel('t [sec]'), ylabel('actual angX [deg]')
% 
% % drift detection
% driftLinCoefs = polyfit(t, mclog.actAngX, 1);
% plot(t, driftLinCoefs(1)*t+driftLinCoefs(2), 'k-')
% title(sprintf('Drift: %.2f + %.2f*t', driftLinCoefs(2), driftLinCoefs(1)))
% 
% % detrending
% resid = mclog.actAngX - driftLinCoefs(1)*t - driftLinCoefs(2);
% residSmooth = conv(resid, ones(1,97)/97, 'same'); % 97 samples = 97[usec] ~ 2 cycles
% figure(4), hold on, plot(t, resid, 'b'), plot(t, residSmooth, 'k-'), grid on, xlabel('time [sec]'), ylabel('detrended actual angX [deg]')
% residResid = resid-residSmooth;
% [maxVals, ~] = findpeaks(residResid);
% [minVals, ~] = findpeaks(-residResid);
% meanAmp = (mean(maxVals) + mean(minVals))/2;
% title(sprintf('mean oscillation amp: %.3f', meanAmp))
% 
% % spectral analysis
% paddingRatio = 100;
% F = fft([mclog.actAngX, zeros(1,(paddingRatio-1)*n)]); F = fftshift(F/max(abs(F)));
% % F = fft([resid, zeros(1,(paddingRatio-1)*n)]); F = fftshift(F/max(abs(F)));
% f = (0:paddingRatio*n-1)/(paddingRatio*n)*fs; f(f>=fs/2) = f(f>=fs/2)-fs; f = fftshift(f);
% figure(5), hold on, plot(f, mag2db(abs(F)), 'b'), grid on, xlabel('freq [Hz]'), ylabel('actual angX spectrum [dB]')
% plot(f, mag2db(abs(1./f))+47, 'k-')
end

%% actual Y multiple frame analysis
for k = 1:1
% nLogs = length(mclogs);
% xDrift = cell(1, nLogs);
% maxLinCoefs = cell(1, nLogs);
% minLinCoefs = cell(1, nLogs);
% 
% figure(6)
% hold all
% for iLog = 1:nLogs
%     % basic plot
%     y = mclogs{iLog}.actAngY;
%     x = mclogs{iLog}.actAngX;
%     t = (0:length(y)-1)/1e6;
%     plot(x, y, '.-')
%     
%     % local drift detection
%     driftLinCoefs = polyfit(t, x, 1);
%     xDrift{iLog} = driftLinCoefs(1)*t+driftLinCoefs(2);
%     [maxVals, maxIdcs] = findpeaks(y);
%     maxLinCoefs{iLog} = polyfit(xDrift{iLog}(maxIdcs), maxVals, 1);
%     [minVals, minIdcs] = findpeaks(-mclog.actAngY);
%     minLinCoefs{iLog} = polyfit(xDrift{iLog}(minIdcs), -minVals, 1);
% end
% grid on, xlabel('actual angX [deg]'), ylabel('actual angY [deg]')
% 
% % global drift detection
% allDriftsX = zeros(1,0);
% allDriftsYmax = zeros(1,0);
% allDriftsYmin = zeros(1,0);
% for iLog = 1:nLogs
%     yMaxDrift = maxLinCoefs{iLog}(1)*xDrift{iLog}+maxLinCoefs{iLog}(2);
%     plot(xDrift{iLog}, yMaxDrift, 'k--', 'linewidth', 2)
%     yMinDrift = minLinCoefs{iLog}(1)*xDrift{iLog}+minLinCoefs{iLog}(2);
%     plot(xDrift{iLog}, yMinDrift, 'k--', 'linewidth', 2)
%     yMeanLinCoefs = (maxLinCoefs{iLog}+minLinCoefs{iLog})/2;
%     plot(xDrift{iLog}, yMeanLinCoefs(1)*xDrift{iLog}+yMeanLinCoefs(2), 'k--')
%     allDriftsX = [allDriftsX, xDrift{iLog}];
%     allDriftsYmax = [allDriftsYmax, yMaxDrift];
%     allDriftsYmin = [allDriftsYmin, yMinDrift];
% end
% [allDriftsX, sortIdcs] = sort(allDriftsX);
% allDriftsYmax = allDriftsYmax(sortIdcs);
% allDriftsYmin = allDriftsYmin(sortIdcs);
% maxLinCoefs = polyfit(allDriftsX, allDriftsYmax, 1);
% minLinCoefs = polyfit(allDriftsX, allDriftsYmin, 1);
% meanLinCoefs = (maxLinCoefs+minLinCoefs)/2;
% amp = (maxLinCoefs(1)-minLinCoefs(1))/2*allDriftsX + (maxLinCoefs(2)-minLinCoefs(2))/2;
% ampChange = 100*(amp(end)-amp(1))/amp(1);
% title(sprintf('Drift: %.3f + %.3f*x ; Amp change: %.1f%%', meanLinCoefs(2), meanLinCoefs(1), ampChange))
end

%% actual X multiple frame analysis
for k = 1:1
% nLogs = length(mclogs);
% xDrift = cell(1, nLogs);
% xVals = cell(1, nLogs);
% 
% figure(7)
% hold all
% for iLog = 1:nLogs
%     % local drift detection
%     xVals{iLog} = mclogs{iLog}.actAngX;
%     t = (0:length(xVals{iLog})-1)/1e6;
%     driftLinCoefs = polyfit(t, xVals{iLog}, 1);
%     xDrift{iLog} = driftLinCoefs(1)*t+driftLinCoefs(2);
%     plot(xDrift{iLog}, xVals{iLog}, '-')
% end
% grid on, xlabel('angX trend [deg]'), ylabel('actual angX [deg]')
% figure(8), hold all, plot(cellfun(@mean, xDrift), cellfun(@(x) x(end)-x(1), xDrift), 'o'), grid on, xlabel('mean angX of capture [deg]'), ylabel('capture angX drift [deg]'), legend('0404', '0404x', '0312')
% 
% % detrending
% residSmooth = cell(1,0);
% residResid = cell(1,0);
% figure(9)
% hold all
% for iLog = 1:nLogs
%     resid = xVals{iLog} - xDrift{iLog};
%     plot(xDrift{iLog}, resid)
%     residSmooth{iLog} = conv(resid, ones(1,97)/97, 'same'); % 97 samples = 97[usec] ~ 2 cycles
%     residResid{iLog} = resid-residSmooth{iLog};
% end
% for iLog = 1:nLogs
%     plot(xDrift{iLog}, residSmooth{iLog}, 'k-')
% end
% grid on, xlabel('actual angX trend [deg]'), ylabel('detrended actual angX [deg]'), xlim([-12.5, 10]), ylim([-0.06, 0.06])
end

%% PZR single frame analysis
for k = 1:1
% fs = 1e6;
% n = length(mclog.t);
% t = mclog.t/fs;
% 
% % simple plot
% figure(10)
% hold all
% for iPzr = 1:3
%     h(iPzr) = plot(t, eval(sprintf('mclog.PZR%d', iPzr)), '.-');
% end
% hLeg = legend('PZR1', 'PZR2', 'PZR3');
% set(hLeg, 'AutoUpdate', 'off')
% grid on, xlabel('time [sec]'), ylabel('measurement')
% 
% % envelope detection
% driftCoefs = cell(1,3);
% txt = cell(1,3);
% for iPzr = 1:3
%     [maxVals, maxIdcs] = findpeaks(eval(sprintf('mclog.PZR%d', iPzr)));
%     maxLinCoefs = polyfit(t(maxIdcs), maxVals, 1);
%     plot(t, maxLinCoefs(1)*t + maxLinCoefs(2), 'k--', 'linewidth', 2, 'color', 0.66*get(h(iPzr), 'color'))
%     
%     [minVals, minIdcs] = findpeaks(-eval(sprintf('mclog.PZR%d', iPzr)));
%     minLinCoefs = polyfit(t(minIdcs), -minVals, 1);
%     plot(t, minLinCoefs(1)*t + minLinCoefs(2), 'k--', 'linewidth', 2, 'color', 0.66*get(h(iPzr), 'color'))
%     
%     driftCoefs{iPzr} = (maxLinCoefs+minLinCoefs)/2;
%     drift = driftCoefs{iPzr}(1)*t + driftCoefs{iPzr}(2);
%     plot(t, drift, 'k--', 'color', 0.66*get(h(iPzr), 'color'))
%     amp = (maxLinCoefs(1)-minLinCoefs(1))/2*t + (maxLinCoefs(2)-minLinCoefs(2))/2;
%     ampChange = 100*(amp(end)-amp(1))/amp(1);
%     txt{iPzr} = sprintf('PZR%d Drift: %.3f + %.2f*t ; Amp change: %.1f%%', iPzr, driftCoefs{iPzr}(2), driftCoefs{iPzr}(1), ampChange);
% end
% title(sprintf('%s\n%s\n%s', txt{1}, txt{2}, txt{3}))
% 
% % detrending
% figure(11)
% hold all
% for iPzr = 1:3
%     drift = driftCoefs{iPzr}(1)*t + driftCoefs{iPzr}(2);
%     resid = eval(sprintf('mclog.PZR%d', iPzr)) - drift;
%     plot(t, resid, '.-')
% end
% hLeg = legend('PZR1', 'PZR2', 'PZR3');
% grid on, xlabel('time [sec]'), ylabel('detrended measurement')
% % detrended envelope analysis
% if true
%     [maxVals, maxIdcs] = findpeaks(resid);
%     tInterp = (100:1:3000)/fs;
%     maxInterp = interp1(t(maxIdcs), maxVals, tInterp, 'pchip');
%     plot(tInterp, maxInterp, 'k--')
%     [sineFreq, sineAmp, sinePhase] = EstimateSineParams(maxInterp-mean(maxInterp), fs);
%     plot(tInterp, mean(maxInterp)+sineAmp*cos(2*pi*sineFreq*(tInterp-tInterp(1))+sinePhase), 'k-')
%     paddingRatio = 100;
%     fInterp = (0:paddingRatio*length(tInterp)-1)/(paddingRatio*length(tInterp))*fs; fInterp(fInterp>=fs/2) = fInterp(fInterp>=fs/2)-fs; fInterp = fftshift(fInterp);
%     FInterp = fft([maxInterp-mean(maxInterp), zeros(1,(paddingRatio-1)*length(tInterp))]); FInterp = fftshift(abs(FInterp));
%     [FInterpMax, fInterpMax] = max(FInterp .* double(fInterp>0));
%     figure(12), hold on, plot(fInterp, mag2db(FInterp)), grid on, xlabel('freq [Hz]'), ylabel('PZR3 slow envelope spectrum [dB]')
%     plot(fInterp(fInterpMax), mag2db(FInterpMax), 'ko')
% end
% 
% % spectral analysis
% paddingRatio = 100; % change to 1000 for fine frequency/phase estimation
% F = cell(1, 3);
% for iPzr = 1:3
%     F{iPzr} = fft([eval(sprintf('mclog.PZR%d', iPzr)), zeros(1,(paddingRatio-1)*n)]); F{iPzr} = fftshift(F{iPzr});
% end
% f = (0:paddingRatio*n-1)/(paddingRatio*n)*fs; f(f>=fs/2) = f(f>=fs/2)-fs; f = fftshift(f);
% figure(13)
% for iPzr = 1:3
%     h(iPzr) = subplot(3,1,iPzr);
%     hold on
%     plot(f, mag2db(abs(F{iPzr})), 'b')
%     [maxVal, maxInd] = max(mag2db(abs(F{iPzr})).*(f>1e3));
%     plot(f(maxInd), maxVal, 'ko')
%     fprintf('PZR%d phase at %.2fHz: %.3f\n', iPzr, f(maxInd), angle(F{iPzr}(maxInd))+pi*(angle(F{iPzr}(maxInd))<0))
%     grid on, xlabel('freq [Hz]'), ylabel(sprintf('PZR%d spectrum [dB]', iPzr))
%     ylim([-30, 60])
% end
% linkaxes(h)
end

%% PZR multiple frame analysis
for k = 1:1
% fs = 1e6;
% nLogs = length(mclogs);
% xDrift{1} = cell(1, nLogs);
% xDrift{2} = cell(1, nLogs);
% xVals{1} = cell(1, nLogs);
% xVals{2} = cell(1, nLogs);
% 
% for iLog = 1:nLogs
%     % local drift detection
%     for ind = 1:2
%         iPzr = 2*ind-1;
%         xVals{ind}{iLog} = eval(sprintf('mclogs{iLog}.PZR%d', iPzr));
%         t = (0:length(xVals{ind}{iLog})-1)/fs;
%         driftLinCoefs = polyfit(t, xVals{ind}{iLog}, 1);
%         xDrift{ind}{iLog} = driftLinCoefs(1)*t+driftLinCoefs(2);
%     end
% end
% 
% % global drift analysis
% if false
%     figure(14)
%     for ind = 1:2
%         iPzr = 2*ind-1;
%         subplot(1,2,ind)
%         hold all
%         for iLog = 1:nLogs
%             plot(xDrift{ind}{iLog}, xVals{ind}{iLog}, '-')
%         end
%         grid on, xlabel('PZR trend'), ylabel('PZR measurement')
%         title(sprintf('PZR%d', iPzr))
%     end
% end
% 
% figure(15)
% for ind = 1:2
%     iPzr = 2*ind-1;
%     subplot(2,1,ind)
%     hold all
%     plot(cellfun(@mean, xDrift{ind}), cellfun(@(x) x(end)-x(1), xDrift{ind}), 'o')
%     grid on, xlabel('mean measurement of capture'), ylabel('capture measurement drift'), legend('0404', '0404x', '0312')
%     title(sprintf('PZR%d', iPzr))
% end
% % polyfitting
% if false
%     driftInterp = linspace(-0.3, 0.3, 1000);
%     signs = {'-', '+'};
%     for ind = 1:2
%         iPzr = 2*ind-1;
%         subplot(2,1,ind)
%         h = get(gca,'children');
%         x = [get(h(1), 'XData'), get(h(2), 'XData'), get(h(3), 'XData')];
%         y = [get(h(1), 'YData'), get(h(2), 'YData'), get(h(3), 'YData')];
%         [x, sortIdcs] = sort(x);
%         y = y(sortIdcs);
%         p = polyfit(x, y, 2);
%         plot(driftInterp, p(1)*driftInterp.^2 + p(2)*driftInterp + p(3), 'k--')
%         legend('0404', '0404x', '0312', 'quad. fit')
%         title(sprintf('PZR%d: %0.3f %s %0.3f*m %s %.3f*m^2', iPzr, p(3), signs{1+p(2)>0}, abs(p(2)), signs{1+p(1)>0}, abs(p(1))))
%     end
% end
end

%% DSM errors single frame analysis
for k = 1:1
% figure(16)
% hold all
% mclog=mclogs{end};
% plot(mclog.actAngX, mclog.actAngY, '.-')
% plot(mclog.angX, mclog.angY, '.-')
% grid on, xlabel('angX [deg]'), ylabel('angY [deg]'), legend('actual', 'DSM')
% 
% actualX = cellfun(@(x) mean(x.actAngX), mclogs);
% measDelay = cellfun(@(x) mean(x.angX-x.actAngX), mclogs);
% figure(17)
% hold all
% plot(actualX, measDelay, 'o')
% grid on, xlabel('actual angX [deg]'), ylabel('angX mean error [deg]'), legend('0404', '0404x', '0312')
% 
% % polyfitting
% if false
%     xInterp = linspace(-15, 15, 1000);
%     signs = {'-', '+'};
%     h = get(gca,'children');
%     x = [get(h(1), 'XData'), get(h(2), 'XData'), get(h(3), 'XData')];
%     y = [get(h(1), 'YData'), get(h(2), 'YData'), get(h(3), 'YData')];
%     [x, sortIdcs] = sort(x);
%     y = y(sortIdcs);
%     p = polyfit(x, y, 2);
%     plot(xInterp, p(1)*xInterp.^2 + p(2)*xInterp + p(3), 'k--')
%     legend('0404', '0404x', '0312', 'quad. fit')
%     title(sprintf('angX offset (actual vs. DSM): %0.3f %s %0.3f*x %s %.3f*x^2', p(3), signs{1+p(2)>0}, abs(p(2)), signs{1+p(1)>0}, abs(p(1))))
% end
% 
% % scan warp analysis
% actualX = cellfun(@(x) mean(x.actAngX), mclogs);
% %actLength = cellfun(@(x) diff(x.actAngX([1,end])), mclogs);
% measLength = cellfun(@(x) diff(x.angX([1,end])), mclogs);
% figure(18)
% hold all
% %plot(actualX, actLength, '-o')
% plot(actualX, measLength, 'o')
% grid on, xlabel('actual angX [deg]'), ylabel('angX drift [deg]'), legend('0404', '0404x', '0312')
% 
% % polyfitting
% if false
%     xInterp = linspace(-15, 15, 1000);
%     signs = {'-', '+'};
%     h = get(gca,'children');
%     x = [get(h(1), 'XData'), get(h(2), 'XData'), get(h(3), 'XData')];
%     y = [get(h(1), 'YData'), get(h(2), 'YData'), get(h(3), 'YData')];
%     [x, sortIdcs] = sort(x);
%     y = y(sortIdcs);
%     p = polyfit(x, y, 1);
%     plot(xInterp, p(1)*xInterp + p(2), 'k--')
%     legend('0404', '0404x', '0312', 'lin. fit')
%     title(sprintf('angX drift: %0.3f %s %0.3f*x', p(2), signs{1+p(1)>0}, abs(p(1))))
% end
end
