% Load the results of the gamma calib for both units (79 and 128) and show
% their graph:
 IR = 0:4095;
 [filepath,~,~] = fileparts(mfilename('fullpath') );
 i = 1;
 for unit = [79,128]
     gammaregsfn = fullfile(filepath,strcat('gammaregsUnit',num2str(unit)));
     data = load(gammaregsfn);
     gammaregs = data.gammaregs;
     fixedIR(i,:) = Utils.applyGamma(IR,12,gammaregs.DIGG.gamma(1:end-1),12,gammaregs.DIGG.gammaScale, gammaregs.DIGG.gammaShift  );
     i = i+1;
 end
tabplot;
plot(fixedIR')
title('Gamma Curve')
legend({'unit79','unit128'},'location','northwest') 
xlabel('Input IR')
ylabel('Out IR')

% Show RX curves before gamma. Calculate their RMS error from the mean rx:
testNames = {'darrUnit79_4dists_from_650';'darrUnit128_5dists'};
titleNames = {'79';'128'};
loadFrom = 'X:\Data\IvCam2\RXCalib\training';
validRange = 12:65;
for i = 1:numel(testNames)
    rx = load(fullfile(loadFrom,testNames{i},'rx_delay.mat'));
    rxregs = rxDelay2regs(rx.rx_delay*2,[]);
    RXDelay(i,:) = rxregs.DEST.rxPWRpd;
    RXDelayOrig(i,:) = rx.rx_delay*2;
end

bias = mean(RXDelay(:,validRange),2);
RXDelayDB = RXDelay - repmat(bias,[1,65]);

tabplot
subplot(211)
plot(linspace(0,4095,65),RXDelayDB'/2,'linewidth',2)
legend(titleNames),grid on
title('RX Delay - Both Units'), xlabel('IR'),ylabel('Delay(mm)')
axis([0,4096,-inf,inf])

subplot(212)
err = abs(RXDelayDB(1,:)-RXDelayDB(2,:))/2;
meanDelay = mean(RXDelayDB);
errorbar(linspace(0,4095,65),meanDelay/2,err/2,'-s','MarkerSize',10,...
    'MarkerEdgeColor','red','MarkerFaceColor','red','linewidth',2)
grid on
title('Mean RX Delay - With Errors'), xlabel('IR'),ylabel('Delay(mm)')
axis([0,4096,-inf,inf])

preGammaErr = sqrt(sum(err(validRange).^2));

% Show rx calib after gamma and calculate the error:
IRVec = linspace(0,4095,65);
for i = 1:2
    gammaIR(i,:) = fixedIR(i,uint16(IRVec)+1);
end
tabplot
subplot(211)
plot(gammaIR(1,:),RXDelayDB(1,:)/2,'linewidth',2),hold on,
plot(gammaIR(2,:),RXDelayDB(2,:)/2,'linewidth',2)
legend(titleNames),grid on
title('RX Delay - Both Units'), xlabel('IR'),ylabel('Delay(mm)')
axis([0,4096,-inf,inf])


