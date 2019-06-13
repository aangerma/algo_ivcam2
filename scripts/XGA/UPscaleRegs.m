fw=Pipe.loadFirmware('X:\Users\hila\XGA\xgaCalib\F9140336\XGA\xga_code26x2_coarseSample1\algo1\PC10\AlgoInternal');
[regs luts]=fw.get();

newReg.GNRL.imgVsize = uint16(768/2);
newReg.JFIL.upscalexyBypass = 0;
newReg.JFIL.upscalex1y0=0; 
newReg.FRMW.coarseSampleRate=uint8(2); 
% regs.FRMW.preCalcBypass=1; 

fw.setRegs(newReg,''); 
[regs2 luts2]=fw.get();
% kerg.FRMW.kRaw=regs.FRMW.kRaw;
% kerg.FRMW.kWorld=regs.FRMW.kWorld;
% kerg.CBUF.spare=regs.CBUF.spare; 
% fw.setRegs(kerg,''); 
% [regs3 luts3]=fw.get();