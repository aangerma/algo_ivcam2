fw = Pipe.loadFirmware('D:\worksapce\ivcam2\algo_ivcam2\+Calibration\releaseConfigCalibVGA');
[regs,luts] = fw.get();

mRegs = regs.RAST;

mRegs.sampleRate = regs.GNRL.sampleRate;
mRegs.codeLength = regs.GNRL.codeLength;
mRegs.sideLobeDir= regs.GNRL.sideLobeDir;
mRegs.imgHsize = regs.GNRL.imgHsize;
mRegs.imgVsize = regs.GNRL.imgVsize;
mRegs.rangeFinder = regs.GNRL.rangeFinder;
mRegs.fastApprox=regs.MTLB.fastApprox(1);
mRegs.chunkExp = 6; % chunk size is 64
mRegs.extraResExp = 2;
mRegs.chunkRate = int32(round(regs.MTLB.txSymbolLength)) * 16 / int32(regs.GNRL.sampleRate);
mRegs.nScansPerPixel = uint8(1);
mLuts.divCma = uint8([0  127   64   42   32   25   21   18   16   14   13   12   11   10    9    8    8    7    7    7    6    6    6    6    5    5    5    5    5    4    4    4]);
mLuts.biltAdaptR = regs.RAST.biltAdaptR;
mLuts.biltSigmoid = regs.RAST.biltSigmoid;
mLuts.biltSpat = regs.RAST.biltSpat; %YC: TODO uint4!!!

mRegs.fastApprox = regs.MTLB.fastApprox(1);


[x,y] = meshgrid(0:640,0:480);
y(:,1:2:end)=flipud(y(:,1:2:end));
y=y(:);x =x (:);
xy = int16([y';x']);

flags = zeros(480,640);
flags(1:2:end) = 1;
flags= uint8(1-flags);
timestamps = reshape(1:480*640,480,640);
timestamps(:,2:2:end)=flipud(timestamps(:,2:2:end));
timestamps = uint32(flipud(timestamps));

cmaPx = uint8(cma./2);
irCmac = uint16(frames2.i*16);

[cmaOut, irMM, flagsOut, pxOut, si, fStats, cmafWin] = Pipe.RAST.cmaFilter(cmaPx, irCmac, flags, timestamps, xy, mRegs, mLuts);
