txregs = [];
changeCode = 0;
changeRes = 0;
if changeCode
    codeLen = 32;
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
if ~isempty(txregs)
    fw.setRegs(txregs,'');
end
regs = fw.get();

outputFolder = 'L520Config';
fw.writeFirmwareFiles(fullfile(outputFolder));
%hw = HWinterface;
%hw.burnCalibConfigFiles(outputFolder)




calVers = 3.03;
regs.FRMW.calibVersion = uint32(hex2dec(single2hex(calVers)));
regs.FRMW.configVersion = uint32(hex2dec(single2hex(calVers)));
fw = Pipe.loadFirmware(fullfile(ivcam2root,'+Calibration/releaseConfigCalibL520'));
regs.DIGG.sphericalEn = true;
fw.setRegs(regs,'');

outputFolder = 'D:\Data\LIDAR\L520\AlgoGen\L520_2';
fw.generateTablesForFw(outputFolder)

hw = HWinterface;
hw.burnCalibConfigFiles(outputFolder)
hw.cmd(sprintf('WrConfigData %s',fullfile(outputFolder,'Start_Stream_ConfigData_Ver_02_04.txt')));
hw.cmd('rst');
clear hw;
hw = HWinterface;
hw.cmd('dirtybitbypass');

fw = Pipe.loadFirmware('\\143.185.124.250\tester data\IDC Data\IVCAM\L520\HENG-2202\F9130303\ALGO1\AlgoInternal')

%{
[~,~, versionBytes] = calibToolVersion;
regs.FRMW.calibVersion = uint32(typecast(versionBytes,'uint32'));
regs.FRMW.configVersion = uint32(typecast(versionBytes,'uint32'));
%}