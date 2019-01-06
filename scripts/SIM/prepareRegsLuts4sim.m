function [regs,luts] = prepareRegsLuts4sim(FW_path, code_length, imgVsize, p)
initFW = fullfile(FW_path); % Folder with csv files with reg names and values
fw = Pipe.loadFirmware(initFW);% Load from a specific folder
txSequence = char(zeros(1,32));
codeSequence = binaryVectorToHex( fliplr(p.laser.txSequence'));
txSequence(1,length(txSequence)- length(codeSequence)+1:end) = codeSequence;
txregs.FRMW.txCode = uint32([hex2dec(txSequence(end-7:end)),hex2dec(txSequence(end-15:end-8)),hex2dec(txSequence(end-23:end-16)),hex2dec(txSequence(1:end-24))]);
txregs.GNRL.codeLength = uint8(code_length);
txregs.FRMW.coarseSampleRate = uint8(2); %GHz
txregs.GNRL.sampleRate = uint8(8);
txregs.GNRL.imgVsize = uint16(60); % TO OVERCOME A BUG
txregs.DEST.baseline = single(0);
txregs.DEST.txFRQpd = single([0 0 0]);
fw.setRegs(txregs,'');
[regs,luts] = fw.get();
% In order to change to a value the reg does not allow
regs.GNRL.imgVsize = uint16(imgVsize);
regs.GNRL.imgHsize = uint16(1);
end

