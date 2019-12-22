function [unitData  ] = thermalValidationRegsState( hw )
[~,unitData.eepromBin] = hw.readAlgoEEPROMtable();
[~,unitData.diggUndistBytes] = hw.cmd('mrdfull 85100000 85102000');
% luts.DIGG.undistModel = typecast(diggUndistBytes(:),'int32');
unitData.regs.GNRL.imgHsize = uint16(hw.read('GNRLimgHsize'));
unitData.regs.GNRL.imgVsize = uint16(hw.read('GNRLimgVsize'));
unitData.regs.DEST.baseline = typecast(hw.read('DESTbaseline$'),'single');
unitData.regs.DEST.baseline2 = typecast(hw.read('DESTbaseline2'),'single');
unitData.regs.DEST.hbaseline = hw.read('DESThbaseline');
unitData.kWorld = hw.getIntrinsics();
unitData.regs.GNRL.zNorm = single(hw.z2mm);
unitData.regs.GNRL.zMaxSubMMExp = uint16(hw.read('GNRLzMaxSubMMExp'));
%     regs.FRMW.mirrorMovmentMode = 1;
%     regs.MTLB.fastApprox = ones(1,8,'logical');
%     regs.DIGG.sphericalEn	= logical(hw.read('DIGGsphericalEn'));
%     regs.DIGG.sphericalOffset	= typecast(hw.read('DIGGsphericalOffset'),'int16');
%     regs.DIGG.sphericalScale 	= typecast(hw.read('DIGGsphericalScale'),'int16');
%     regs.DEST.p2axa = hex2single(dec2hex(hw.read('DESTp2axa')));
%     regs.DEST.p2axb = hex2single(dec2hex(hw.read('DESTp2axb')));
%     regs.DEST.p2aya = hex2single(dec2hex(hw.read('DESTp2aya')));
%     regs.DEST.p2ayb = hex2single(dec2hex(hw.read('DESTp2ayb')));
    
%     regs.FRMW.kWorld = hw.getIntrinsics();
%     regs.FRMW.kRaw = regs.FRMW.kWorld;
%     regs.FRMW.kRaw(7) = single(regs.GNRL.imgHsize) - 1 - regs.FRMW.kRaw(7);
%     regs.FRMW.kRaw(8) = single(regs.GNRL.imgVsize) - 1 - regs.FRMW.kRaw(8);
%     regs.GNRL.zNorm = hw.z2mm;
[~,unitData.rgbCalibData] = hw.cmd('READ_TABLE 10 0'); 
[~,unitData.rgbThermalData] = hw.cmd('READ_TABLE 17 0');
end

