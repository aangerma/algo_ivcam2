fw = Pipe.loadFirmware('D:\worksapce\ivcam2\algo_ivcam2\+Calibration\releaseConfigCalibVGA');
regsFW = fw.get();
mRegs.biltAdapt = regsFW.RAST.biltAdapt;
mRegs.biltAdaptR = regsFW.RAST.biltAdaptR;
mRegs.biltBypass = regsFW.RAST.biltBypass;
mRegs.biltDiag = regsFW.RAST.biltDiag;
mRegs.biltSharpnessR = regsFW.RAST.biltSharpnessR;
mRegs.biltSharpnessS = regsFW.RAST.biltSharpnessS;
mRegs.biltSigmoid = regsFW.RAST.biltSigmoid;
mRegs.biltSpat = regsFW.RAST.biltSpat;




