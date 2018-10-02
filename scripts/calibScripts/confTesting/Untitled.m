hw = HWinterface();
hw.runScript('binaryTrainedConf.txt');
frame = hw.getFrame(); tabplot; subplot(131), imagesc(frame.z/8);subplot(132), imagesc(frame.c);subplot(133), imagesc(frame.i);
hw.runScript('binaryTrainedConfModifiedToRemoveMaxPeak0.txt');
frame = hw.getFrame(); tabplot; subplot(131), imagesc(frame.z/8);subplot(132), imagesc(frame.c);subplot(133), imagesc(frame.i);

for i = 0:1000:20000
    hw.runPresetScript('maReset');
    hw.cmd(sprintf('mwd A0050008 A005000c %04X%04X', (i), (i)))
    hw.runPresetScript('maRestart');
    frame = hw.getFrame(); tabplot; subplot(131), imagesc(frame.z/8);subplot(132), imagesc(frame.c);subplot(133), imagesc(frame.i);
    title(num2str(i));
end