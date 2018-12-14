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

relevantRegs = 'GNRLcodeLength|GNRLtmplLength|RASTcmaBinSize|RASTcmaMaxSamples|RASTsharedDenom|RASTsharedDenomExp|RASTdcCodeNorm|RASTcmaFiltMode|RASTcmacCycPerValid|RASTlnBufCycPerValid|DCORdecRatio|DCORcoarseTmplLength|DCORloopCtrl|DESTambiguityRTD|DESTmaxvalDiv|DESTdecRatio|DESTaltIrSub|DESTaltIrDiv|EXTLauxPItxCode|EXTLauxPItxCodeLength|DCORtmpltFine|DCORtmpltCrse';
% relevantRegs = 'DCORtmpltFine|DCORtmpltCrse';
% relevantRegs = [];

fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\releaseConfigCalib');
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
txregs.GNRL.sampleRate = uint8(8);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code64_dec8.txt');
% Code 32 dec 8 sr 16
% txregs.FRMW.txCode = uint32([hex2dec('69565A99'),0,0,0]);
txregs.FRMW.txCode = uint32([hex2dec('fa99594e'),0,0,0]);
txregs.GNRL.codeLength = uint8(26);   
txregs.FRMW.coarseSampleRate = uint8(2);
txregs.GNRL.sampleRate = uint8(16);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code26_dec8_sr16.txt');

% Code 62 dec 8
txregs.FRMW.txCode = uint32([hex2dec('959AA9A5'),hex2dec('2A55A665'),0,0]);
txregs.GNRL.codeLength = uint8(62);
txregs.FRMW.coarseSampleRate = uint8(1);
txregs.GNRL.sampleRate = uint8(8);
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
fw.genMWDcmd(relevantRegs,'code52_dec8_fix.txt');

% Code 52 coarse dec 4
txregs.FRMW.txCode = uint32([hex2dec('69966665'),hex2dec('000A6AA9'),0,0]);
txregs.GNRL.codeLength = uint8(52);
txregs.FRMW.coarseSampleRate = uint8(2);
fw.setRegs(txregs,'');
fw.get();
fw.genMWDcmd(relevantRegs,'code52_dec4.txt');



hw=HWinterface(fw);



% codevec = vec(fliplr(dec2bin(regs.FRMW.txCode(:),32))')=='1';
% codevec = codevec(1:regs.GNRL.codeLength);
% codevec =flipud(codevec);%ASIC ALIGNMENT
% kF = double(vec(repmat(codevec,1,regs.GNRL.sampleRate)'));

codes = {'64','62','52','31x2'};
for c = [1,3]%1:numel(codes)
    for d = 4
        hwa = hw.assertions
        setCode(hw,codes{c},d);
    end
end

% Code 64 works and we know it.
% Let us try code 62.
txregs = setCode(hw,codes{2},8);
[cma,~] = readCMA(hw);
cma1pix = cma(:,240,240);
codevec = vec(fliplr(dec2bin(txregs.FRMW.txCode(:),32))')=='1';
codevec = codevec(1:txregs.GNRL.codeLength);
codevec = flipud(codevec);%ASIC ALIGNMENT
kF = double(vec(repmat(codevec,1,txregs.GNRL.sampleRate)'));

c = (cconv( cma1pix,kF,numel(kF)));
[~,peakat] = max(c);
subplot(4,1,1);
stem(flipud(kF))
subplot(4,1,2);
stem(cma1pix)
subplot(4,1,3);
stem(circshift(cma1pix,-peakat+1))
subplot(4,1,4);
stem(cconv( circshift(cma1pix,-peakat+1),kF,numel(kF)))