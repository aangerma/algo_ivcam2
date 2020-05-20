function [newAcDataTable,newAcDataStruct,losShift, losScaling] = AC2ResultsToDSM(dataForACTableGeneration,params,newKdepth,relevantPixelsImage)
acDataIn = Calibration.tables.convertBinTableToCalibData(uint8(dataForACTableGeneration.acDataBin), 'Algo_AutoCalibration');
acDataIn.flags = mod(acDataIn.flags(1),2);

regs = Calibration.tables.convertBinTableToCalibData(uint8(dataForACTableGeneration.calibDataBin), 'Algo_Calibration_Info_CalibInfo');

dsmRegs.dsmXscale = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmXscale),'single');
dsmRegs.dsmXoffset = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmXoffset),'single');
dsmRegs.dsmYscale = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmYscale),'single');
dsmRegs.dsmYoffset = typecast(uint32(dataForACTableGeneration.DSMRegs.dsmYoffset),'single');
regs.FRMW.rtdOverX(1:6) = 0;
regs.FRMW.rtdOverY(1:3) = 0;
regs.FRMW.mirrorMovmentMode = 1;
regs.DEST.baseline2 = regs.DEST.baseline^2;


KRaw = params.Kdepth;
KRaw(1,3) = single(params.depthRes(2))-1-KRaw(1,3);
KRaw(2,3) = single(params.depthRes(1))-1-KRaw(2,3);

newKRaw = newKdepth;
newKRaw(1,3) = single(params.depthRes(2))-1-newKRaw(1,3);
newKRaw(2,3) = single(params.depthRes(1))-1-newKRaw(2,3);

preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acDataIn, dsmRegs, params.depthRes, KRaw, relevantPixelsImage);
[losShift, losScaling] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, newKRaw);
newAcDataStruct = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, acDataIn.flags, losShift, losScaling);
newAcDataStruct.flags(2:6) = uint8(0);
newAcDataTable = Calibration.tables.convertCalibDataToBinTable(newAcDataStruct, 'Algo_AutoCalibration');
    
end

