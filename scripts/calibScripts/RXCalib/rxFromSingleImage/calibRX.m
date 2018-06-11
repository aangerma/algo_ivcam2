clear
fw = Pipe.loadFirmware('C:\Temp\ohadTest\AlgoInternal');
[regs,luts] = fw.get();


rxregs.DEST.rxPWRpd = 0*regs.DEST.rxPWRpd;


hw = HWinterface(fw);
fw.setRegs(rxregs, '');
regs = fw.get(); % run bootcalcs
fnrxMWD = 'rxCalib.txt';
fw.genMWDcmd('DESTrx',fnrxMWD);
hw.runScript(fnrxMWD);
hw.shadowUpdate();

d(1) = hw.getFrame(100);


[rxregs,res1] = rxCalibFromFrame(d(1),regs);
fw.setRegs(rxregs, '');
regs = fw.get(); % run bootcalcs
fnrxMWD = 'rxCalib.txt';
fw.genMWDcmd('DESTrx',fnrxMWD);
hw.runScript(fnrxMWD);
hw.shadowUpdate();

d(2) = hw.getFrame(100);
ivbin_viewer({uint16(d(1).z),uint16(d(2).z)})
[rxregs2,res2] = rxCalibFromFrame(d(2),regs);
mean(sqrt(res1.errorIm(:).^2),'omitnan')
mean(sqrt(res1.errorImTheoryFix(:).^2),'omitnan')
mean(sqrt(res2.errorIm(:).^2),'omitnan')
tabplot
errorbar(1:64,res1.rxMean,res1.rxSTD)
hold on
errorbar(1:64,res2.rxMean,res2.rxSTD)
