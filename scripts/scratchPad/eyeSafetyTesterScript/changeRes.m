clear
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initScript');
regs.GNRL.imgHsize = uint16(1280);
regs.GNRL.imgVsize = uint16(960);
fw.setRegs(regs,'');
fw.get();
fw.genMWDcmd([],'960x1280.txt');