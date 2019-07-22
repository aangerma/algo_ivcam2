% load XGA calib
fw_XgaCalib=Pipe.loadFirmware('X:\Users\hila\FWBootCalcs\XGA\fw\withCoarseMaskingAndPreset\New folder\PC22\AlgoInternal');
RegsXGAstream=fw_XgaCalib.get(); 
% change to VGA (RES + relevent config)
GenralVGAfw=Pipe.loadFirmware('C:\GIT\ALGO_Projects\algo_ivcam2\+Calibration\releaseConfigCalibVGA'); 
VGAregs=GenralVGAfw.get(); 
newRegs.GNRL.imgHsize=VGAregs.GNRL.imgHsize; 
newRegs.GNRL.imgVsize=VGAregs.GNRL.imgVsize; 
newRegs.GNRL.codeLength=VGAregs.GNRL.codeLength; 
newRegs.FRMW.txCode=VGAregs.FRMW.txCode; 
newRegs.FRMW.coarseSampleRate=VGAregs.FRMW.coarseSampleRate; 
newRegs.FRMW.cbufMargin=VGAregs.FRMW.cbufMargin;
newRegs.FRMW.externalHsize=VGAregs.FRMW.externalHsize;
newRegs.FRMW.externalVsize=VGAregs.FRMW.externalVsize;
newRegs.JFIL.irShadingScale=VGAregs.JFIL.irShadingScale; 
% set preset regs for dcor masking
newRegs.FRMW.algoThermalLoopOffset=single(56.2560296343196); 
newRegs.FRMW.coarseMaskingMax=uint16(20); 
%%
fw_XgaCalibVgastream=Pipe.loadFirmware('X:\Users\hila\FWBootCalcs\XGA\fw\withCoarseMaskingAndPreset\New folder\PC22\AlgoInternal');
fw_XgaCalibVgastream.setRegs(newRegs,''); 
% autogen for vga with xga calib
RegsVGAstream=fw_XgaCalibVgastream.get(); 