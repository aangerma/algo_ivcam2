% set DC as 40-55:
hw = HWinterface;

inputIdx = 1;
fwpath = fullfile('C:\source\algo_ivcam2\+Calibration\releaseConfigCalibVXGA');
fw = Pipe.loadFirmware(fwpath); 
regs.DEST.confw1 = int8([0,0,0,0]);
regs.DEST.confw1(inputIdx) = 1;
regs.DEST.confv = int8([0,0,0,0]);
regs.DEST.confactIn = int16([-128,255]);
regs.DEST.confq = int8([4,0]);
regs.DEST.confactOt = int16([0,255]);
regs.DEST.confw2 = int8([0,0,0,0]);

regs.RAST.dcLevel(:) = uint8([95,95,95]); % the lut get distance from 70 in abs
regs.RAST.confDC = zeros(1,64,'uint8');
indices1to15 = fliplr(19:51);
regs.RAST.confDC(indices1to15) = round(linspace(1,15,numel(indices1to15)));

fw.setRegs(regs,'');
regs = fw.get();

scname = 'confAsDC.txt';
fw.genMWDcmd('DESTconf|RASTconfDC|RASTdcLevel',scname);
hw.runScript(scname);
hw.shadowUpdate;

%%
cmaLength = 52*8;
maxConfSum = cmaLength*(127);
imgDcLevel = int16(regs.RAST.dcLevel(1));



confSum = (0:127)*cmaLength;
% 40% to 54% should get 1 to 15
diffDC = min(63, abs(int16(bitshift((uint64(confSum)*uint64(regs.RAST.dcCodeNorm)), -22))-imgDcLevel));
%confDC = uint8(15-min(15, bitshift(diffDC, -1)));
confDC = map(regs.RAST.confDC, diffDC+1);

figure, plot(diffDC,confDC)
figure, plot(confSum/(127*cmaLength),confDC)

dutyCycle = confSum(:)/(127*cmaLength);
confidence = confDC(:);
T = table(dutyCycle,confidence);
writetable(T,'dutyCycle2Conf.csv')