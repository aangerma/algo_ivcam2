clear
fw = Firmware;
fw.get();

regs.GNRL.codeLength = uint8(16);
regs.GNRL.sampleRate = uint8(8);
regs.FRMW.coarseSampleRate = uint8(2);
fw.setRegs(regs,'');
[regs, luts] = fw.get();
% fw.genMWDcmd('tmpl','gen2tmpl.txt');
lutsDCOR = luts.DCOR;
save lutsDCORgen1.mat lutsDCOR