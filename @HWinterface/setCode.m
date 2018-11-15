function [  ] = setCode( obj,txregs,forRF)
%SETCODE sets new code
% forRF states if we are in range finder mode. txregs should contain FRMWtxCode, GNRLcodeLength,FRMWcoarseSampleRate.
% Sample rate of 8G is asumed. Example input for code 52 with deimation of
% 4:
% txregs.FRMW.txCode = uint32([hex2dec('69966665'),hex2dec('000A6AA9'),0,0]);
% txregs.GNRL.codeLength = uint8(52);
% txregs.FRMW.coarseSampleRate = uint8(1);


fw = Firmware;
if forRF
    relevantRegs = 'GNRLcodeLength|GNRLtmplLength|RASTsharedDenom|RASTsharedDenomExp|RASTdcCodeNorm|DCORdecRatio|DCORcoarseTmplLength|DCORloopCtrl|DESTambiguityRTD|DESTmaxvalDiv|DESTdecRatio|DESTaltIrSub|DESTaltIrDiv|EXTLauxPItxCode|EXTLauxPItxCodeLength|DCORtmpltFine|DCORtmpltCrse';
else
    relevantRegs = 'GNRLcodeLength|GNRLtmplLength|RASTcmaBinSize|RASTcmaMaxSamples|RASTsharedDenom|RASTsharedDenomExp|RASTdcCodeNorm|RASTcmaFiltMode|RASTcmacCycPerValid|RASTlnBufCycPerValid|DCORdecRatio|DCORcoarseTmplLength|DCORloopCtrl|DESTambiguityRTD|DESTmaxvalDiv|DESTdecRatio|DESTaltIrSub|DESTaltIrDiv|EXTLauxPItxCode|EXTLauxPItxCodeLength|DCORtmpltFine|DCORtmpltCrse';
end
txregs.GNRL.sampleRate = uint8(8);
fw.setRegs(txregs,'');
fw.get();
scname = strcat(tempname,'.txt');
fw.genMWDcmd(relevantRegs,scname);


obj.runPresetScript('maReset');
pause(0.1);
obj.runScript(scname);
pause(0.1);
obj.runPresetScript('maRestart');
pause(0.1);
obj.cmd('mwd a00d01ec a00d01f0 00000001 // EXTLauxShadowUpdateFrame');
pause(0.1);

end

