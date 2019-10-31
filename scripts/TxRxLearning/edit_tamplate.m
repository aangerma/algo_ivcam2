% Edit DCOR.FRMW.fwBootCalc.m
hw = HWinterface;
fw = Pipe.loadFirmware(fullfile(ivcam2root,'+Calibration', 'releaseConfigCalib360p'));

txregs = [];
code=Codes.propCode(32,1);
code=repmat(code',2,1);
code=code(:);
txregs.FRMW.txCode = Utils.bin2uint32(flip(code)); %uint32([1701406058,2509925030,0,0]);
% txregs.FRMW.calibVersion = uint32(hex2dec(single2hex(calibToolVersion)));
% txregs.FRMW.configVersion = uint32(hex2dec(single2hex(calibToolVersion)));
fw.setRegs(txregs,'');
fw.get();

relevantRegs = 'EXTLauxPItxCode|DCORtmpltFine|DCORtmpltCrse';
fw.genMWDcmd(relevantRegs,'codeScript.txt');

hw.runPresetScript('maReset');
pause(0.1);
% hw.runScript('codeScript.txt');
% hw.runScript('codeScript32Our_new.txt');
hw.runScript('codeScript32Orig.txt');

pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.cmd('mwd a00d01ec a00d01f0 00000111 // EXTLauxShadowUpdateFrame');
pause(0.1);

