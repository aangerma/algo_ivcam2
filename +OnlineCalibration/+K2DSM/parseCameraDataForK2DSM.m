function [acData,regs,dsmRegs] = parseCameraDataForK2DSM(DSMRegs,acDataBin,calibDataBin,binWithHeaders)

if binWithHeaders
   headerSize = 16;
   acDataBin = acDataBin(headerSize+1:end);
   calibDataBin = calibDataBin(headerSize+1:end);
end
acData = Calibration.tables.convertBinTableToCalibData(uint8(acDataBin), 'Algo_AutoCalibration');
acData.flags = mod(acData.flags(1),2);
regs = Calibration.tables.convertBinTableToCalibData(uint8(calibDataBin), 'Algo_Calibration_Info_CalibInfo');
dsmRegs.dsmXscale = typecast(uint32(DSMRegs.dsmXscale),'single');
dsmRegs.dsmXoffset = typecast(uint32(DSMRegs.dsmXoffset),'single');
dsmRegs.dsmYscale = typecast(uint32(DSMRegs.dsmYscale),'single');
dsmRegs.dsmYoffset = typecast(uint32(DSMRegs.dsmYoffset),'single');
regs.FRMW.rtdOverX(1:6) = 0;
regs.FRMW.rtdOverY(1:3) = 0;
regs.FRMW.mirrorMovmentMode = 1;
regs.DEST.baseline2 = regs.DEST.baseline^2;

end

