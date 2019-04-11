function roiRegs = readRoiRegs(hw)
    spares = hw.read('diggspare');
    roiRegs.FRMW.calMarginL = int16(bitshift(spares(7),-16));
    roiRegs.FRMW.calMarginR = int16(spares(7) - int32(roiRegs.FRMW.calMarginL)*2^16);
    roiRegs.FRMW.calMarginT = int16(bitshift(spares(8),-16));
    roiRegs.FRMW.calMarginB = int16(spares(8) - int32(roiRegs.FRMW.calMarginT)*2^16);
end