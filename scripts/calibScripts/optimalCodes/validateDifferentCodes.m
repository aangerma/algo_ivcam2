% Write 5 different Codes (later on expand so each has dec ratio of 4 or
% 8).
% Validate them by comparing the CMA. See the hamming distance (after cyclic shifting). 


% Code 64 (default)
% FRMWtxCode_000 h6569656A
% FRMWtxCode_001 h959A6AA6
% FRMWtxCode_002 h00000000
% FRMWtxCode_003 h00000000
% GNRLcodeLength h00000040
% GNRLsampleRate h00000008

% Code 62
% FRMWtxCode_000 h959AA9A5
% FRMWtxCode_001 h2A55A665
% GNRLcodeLength d62

% Code31x2 unbalanced
% FRMWtxCode_000 h69B121C1
% FRMWtxCode_001 h3F2A33DD
% GNRLcodeLength d62

% Code 52 
% FRMWtxCode_000 h69966665
% FRMWtxCode_001 h000A6AA9
% GNRLcodeLength d52

% Check the following codes:
% 1. Code 64 coarse dec 4.
% 2. Code 64 coarse dec 8.
% 3. Code 62 coarse dec 4.
% 4. Code 62 coarse dec 8.
% 5. Code 31x2 coarse dec 4.
% 6. Code 31x2 coarse dec 8.
% 7. Code 52 coarse dec 4.
% 8. Code 52 coarse dec 8.

relevantRegs = 'GNRLcodeLength|GNRLtmplLength|DIGGnotch|RASTsharedDenom|RASTsharedDenomExp|RASTdcCodeNorm|RASTcmacCycPerValid|RASTlnBufCycPerValid|DCORdecRatio|DCORcoarseTmplLength|DCORloopCtrl|DESTambiguityRTD|DESTmaxvalDiv|DESTdecRatio|DESTaltIrSub|DESTaltIrDiv|FRMWcoarseSampleRate|FRMWtxCode|EXTLauxPItxCode|EXTLauxPItxCodeLength|DCORtmpltFine|DCORtmpltCrse|EXTLauxShadowUpdate';
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initScript');
[regs,luts] = fw.get();

% Code 64 dec 4
txregs.FRMW.txCode = uint32([hex2dec('6569656A'),hex2dec('959A6AA6'),0,0]);
txregs.GNRL.codeLength = uint8(64);
txregs.FRMW.coarseSampleRate = uint8(2);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code64_dec4.txt');
% Code 64 dec 8
txregs.FRMW.txCode = uint32([hex2dec('6569656A'),hex2dec('959A6AA6'),0,0]);
txregs.GNRL.codeLength = uint8(64);
txregs.FRMW.coarseSampleRate = uint8(1);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code64_dec8.txt');

% Code 62 dec 8
txregs.FRMW.txCode = uint32([hex2dec('959AA9A5'),hex2dec('2A55A665'),0,0]);
txregs.GNRL.codeLength = uint8(62);
txregs.FRMW.coarseSampleRate = uint8(1);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code62_dec8.txt');

% Code 62 dec 4
txregs.FRMW.txCode = uint32([hex2dec('959AA9A5'),hex2dec('2A55A665'),0,0]);
txregs.GNRL.codeLength = uint8(62);
txregs.FRMW.coarseSampleRate = uint8(2);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code62_dec4.txt');


% Code31x2 unbalanced dec 8
txregs.FRMW.txCode = uint32([hex2dec('69B121C1'),hex2dec('3F2A33DD'),0,0]);
txregs.GNRL.codeLength = uint8(62);
txregs.FRMW.coarseSampleRate = uint8(1);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code31x2_dec8.txt');

% Code31x2 unbalanced dec 4
txregs.FRMW.txCode = uint32([hex2dec('69B121C1'),hex2dec('3F2A33DD'),0,0]);
txregs.GNRL.codeLength = uint8(62);
txregs.FRMW.coarseSampleRate = uint8(2);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code31x2_dec4.txt');

% Code 52 coarse dec 8
txregs.FRMW.txCode = uint32([hex2dec('69966665'),hex2dec('000A6AA9'),0,0]);
txregs.GNRL.codeLength = uint8(52);
txregs.FRMW.coarseSampleRate = uint8(1);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code52_dec8.txt');

% Code 52 coarse dec 4
txregs.FRMW.txCode = uint32([hex2dec('69966665'),hex2dec('000A6AA9'),0,0]);
txregs.GNRL.codeLength = uint8(52);
txregs.FRMW.coarseSampleRate = uint8(2);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code52_dec4.txt');



hw=HWinterface(fw);

hw.runPresetScript('maReset');
pause(0.1);
hw.runScript('init.txt');
pause(0.1);
% mwd a0010104 a0010108 19DDDDFD // Force disables JFIL
hw.runPresetScript('maRestart');
pause(0.1);
hw.shadowUpdate();


frame = hw.getFrame();
tabplot; subplot(1,2,1); imagesc(frame.z/8); subplot(1,2,2); imagesc(frame.i);


hw.runPresetScript('maReset');
pause(0.1);
hw.runScript('code64_dec4.txt');
pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.shadowUpdate();

frame = hw.getFrame();
tabplot; subplot(1,2,1); imagesc(frame.z/8); subplot(1,2,2); imagesc(frame.i);

% codevec = vec(fliplr(dec2bin(regs.FRMW.txCode(:),32))')=='1';
% codevec = codevec(1:regs.GNRL.codeLength);
% codevec =flipud(codevec);%ASIC ALIGNMENT
% kF = double(vec(repmat(codevec,1,regs.GNRL.sampleRate)'));