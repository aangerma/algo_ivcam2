txregs = [];
changeCode = 1;
changeRes = 1;
if changeCode
    codeLen = 16;
    txregs.FRMW.txCode = Utils.bin2uint32(flip(Codes.propCode(codeLen,1)));
    txregs.GNRL.codeLength = uint8(codeLen);
    txregs.FRMW.coarseSampleRate = uint8(4);
    txregs.GNRL.sampleRate = uint8(16);
end

if changeRes
    txregs.GNRL.imgHsize  = uint16(152);
    txregs.GNRL.imgVsize  = uint16(232);
    txregs.FRMW.xfov  = single(27).*ones(1,5);
    txregs.FRMW.yfov  = single(45).*ones(1,5);
end

fw = Pipe.loadFirmware(fullfile(ivcam2root,'+Calibration/releaseConfigCalibL520'));
fw.setRegs(txregs,'');
fw.get();

outputFolder = 'L520Config_v1';
fw.writeFirmwareFiles(fullfile(outputFolder),false);
hw = HWinterface;
hw.burnCalibConfigFiles(outputFolder)
