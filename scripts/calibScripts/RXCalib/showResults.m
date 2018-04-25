% 1. Load RX Delays
clear
testNames = {'darrUnit79_2dists_CB_from_650';'darrUnit79_4dists_from_650';'darrUnit128_1dists_CB';'darrUnit128_5dists' ;'darrUnit121_2dists_CB';'darrUnit121_4dists' };
titleNames = {'79-CB';'79-Smooth';'128-CB';'128-Smooth';'121-CB';'121-Smooth'};
loadFrom = 'X:\Data\IvCam2\RXCalib\training';

for i = 1:numel(testNames)
    rx = load(fullfile(loadFrom,testNames{i},'rx_delay.mat'));
    rxregs = rxDelay2regs(rx.rx_delay*2,[]);
    RXDelay(i,:) = rxregs.DEST.rxPWRpd;
    RXDelayOrig(i,:) = rx.rx_delay*2;
end


bias = mean(RXDelayOrig(:,650:4080),2);
RXDelayDB = RXDelayOrig - repmat(bias,[1,4096]);
figure(1)
ax1 = subplot(231);
plot(RXDelayDB([1,2],:)'),axis([0,4096,-inf,inf])
legend(titleNames{1:2}),grid on
title('RX Delay - Unit 79'), xlabel('IR'),ylabel('Delay(mm)')

ax2 = subplot(232);
plot(RXDelayDB([3,4],:)');
legend(titleNames{3:4}),grid on,axis([0,4096,-inf,inf])
title('RX Delay - Unit 128'), xlabel('IR'),ylabel('Delay(mm)')

ax3 = subplot(233);
plot(RXDelayDB([5,6],:)');
legend(titleNames{5:6}),grid on,axis([0,4096,-inf,inf])
title('RX Delay - Unit 121'), xlabel('IR'),ylabel('Delay(mm)')

ax4 = subplot(2,3,[4,5,6]);
plot(RXDelayDB')
legend(titleNames{[1,2,3,4,5,6]}),grid on,axis([0,4096,-inf,inf])
title('RX Delay - Both Units'), xlabel('IR'),ylabel('Delay(mm)')
linkaxes([ax1,ax2,ax3,ax4],'xy')

figure(2)
subplot(211)
plot(linspace(0,4095,65),RXDelay([2,4],:)'/2,'linewidth',2)
legend(titleNames{[2,4]}),grid on
title('RX Delay - Both Units'), xlabel('IR'),ylabel('Delay(mm)')
axis([0,4096,-inf,inf])

subplot(212)
err = abs(RXDelay(2,:)-RXDelay(4,:))/2;
meanDelay = mean(RXDelay([2,4],:));
errorbar(linspace(0,4095,65),meanDelay/2,err/2,'-s','MarkerSize',10,...
    'MarkerEdgeColor','red','MarkerFaceColor','red','linewidth',2)
grid on
title('Mean RX Delay - With Errors'), xlabel('IR'),ylabel('Delay(mm)')
axis([0,4096,-inf,inf])
