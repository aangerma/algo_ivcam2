function [regs,eepromRegs] = readDFZRegsForThermalCalculation(hw,checkAssert,calibParams)
   
    regs = hw.readAlgoEEPROMtable();
    eepromRegs = regs;
    regs.GNRL.imgHsize = hw.read('GNRLimgHsize');
    regs.GNRL.imgVsize = hw.read('GNRLimgVsize');
    regs.FRMW.mirrorMovmentMode = 1;
    regs.MTLB.fastApprox = ones(1,8,'logical');
    regs.DEST.baseline2 = typecast(hw.read('DESTbaseline2'),'single');
    regs.DEST.hbaseline = hw.read('DESThbaseline');
    regs.DIGG.sphericalOffset	= typecast(hw.read('DIGGsphericalOffset'),'int16');
    regs.DIGG.sphericalScale 	= typecast(hw.read('DIGGsphericalScale'),'int16');
    regs.DEST.p2axa = hex2single(dec2hex(hw.read('DESTp2axa')));
    regs.DEST.p2axb = hex2single(dec2hex(hw.read('DESTp2axb')));
    regs.DEST.p2aya = hex2single(dec2hex(hw.read('DESTp2aya')));
    regs.DEST.p2ayb = hex2single(dec2hex(hw.read('DESTp2ayb')));
    
    regs.FRMW.kWorld = hw.getIntrinsics();
    regs.FRMW.kRaw = regs.FRMW.kWorld;
    regs.FRMW.kRaw(7) = single(regs.GNRL.imgHsize) - 1 - regs.FRMW.kRaw(7);
    regs.FRMW.kRaw(8) = single(regs.GNRL.imgVsize) - 1 - regs.FRMW.kRaw(8);
    regs.GNRL.zNorm = hw.z2mm;
    regs.GNRL.zMaxSubMMExp = hw.read('GNRLzMaxSubMMExp');
    
    if calibParams.gnrl.sphericalMode
        regs.DIGG.sphericalScale = int16(double(regs.DIGG.sphericalScale).*calibParams.gnrl.sphericalScaleFactors);
        regs.DEST.depthAsRange = 1; 
        regs.DIGG.sphericalEn = 1;
        regs.DEST.baseline = single(0);
        regs.DEST.baseline2 = single(0);
    end
    if checkAssert
       assert(all(regs.FRMW.dfzVbias ~= 0),'Unit probably not was not calibrated in Algo1. No calibration vBias1 available.\n');
    end
end

