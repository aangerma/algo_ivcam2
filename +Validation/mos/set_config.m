sort_bypass_mode = 0;
JFIL_sharpS = 0;
JFIL_sharpR = 32;
RAST_sharpS = 0;
RAST_sharpR = 2;

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