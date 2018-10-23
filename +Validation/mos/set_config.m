sort_bypass_mode = 0;
JFIL_sharpS = 0;
JFIL_sharpR = 12;
RAST_sharpS = 0;
RAST_sharpR = 2;

regs.RAST.biltAdapt = uint8(0);
regs.JFIL.biltAdaptR = uint8(0);
regs.JFIL.biltAdaptS = uint8(0);

regs.RAST.biltSharpnessS = uint8(RAST_sharpS);
regs.RAST.biltSharpnessR = uint8(RAST_sharpR);

regs.JFIL.sort1bypassMode = uint8(sort_bypass_mode);
regs.JFIL.sort2bypassMode = uint8(sort_bypass_mode);
regs.JFIL.sort3bypassMode = uint8(sort_bypass_mode);

regs.JFIL.biltSharpnessS = uint8(JFIL_sharpS);
regs.JFIL.bilt1SharpnessR = uint8(JFIL_sharpR);
regs.JFIL.bilt2SharpnessR = uint8(JFIL_sharpR);
regs.JFIL.bilt3SharpnessR = uint8(JFIL_sharpR);


% disable adapt
hw.setReg('RASTbiltAdapt$',uint8(0));
hw.setReg('JFILbiltAdaptR',uint8(0));
hw.setReg('JFILbiltAdaptS',uint8(0));

hw.setReg('JFILsort1bypassMode',uint8(sort_bypass_mode));
hw.setReg('JFILsort2bypassMode',uint8(sort_bypass_mode));
hw.setReg('JFILsort3bypassMode',uint8(sort_bypass_mode));

hw.setReg('JFILbiltSharpnessS',uint8(JFIL_sharpS));

hw.setReg('JFILbilt1SharpnessR',uint8(JFIL_sharpR));
hw.setReg('JFILbilt2SharpnessR',uint8(JFIL_sharpR));
hw.setReg('JFILbilt3SharpnessR',uint8(JFIL_sharpR));

hw.setReg('RASTbiltSharpnessR',uint8(RAST_sharpR));
hw.setReg('RASTbiltSharpnessS',uint8(RAST_sharpS));


hw.shadowUpdate();




