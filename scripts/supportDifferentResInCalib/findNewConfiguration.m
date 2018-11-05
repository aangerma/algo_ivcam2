clear
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
regsNew.GNRL.imgVsize = uint16(360);
% regsNew.PCKR.padding = 480*640-uint32(regsNew.GNRL.imgVsize)*640;
fw.setRegs(regsNew,'');
regs = fw.get();

hw = HWinterface();
hw.getFrame();
fnAlgoInitMWD = '36o640.txt';
fw.genMWDcmd('^(?!MTLB|EPTG|FRMW|EXTLauxShadow.*$).*',fnAlgoInitMWD);
hw.runPresetScript('maReset');
pause(0.1);
hw.runScript(fnAlgoInitMWD);
pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.runPresetScript('maReset');
hw.runPresetScript('maRestart');
%         hw.cmd('mwd a00d01ec a00d01f0 00000001 // EXTLauxShadowUpdateFrame');
hw.shadowUpdate();
fprintf('Done\n');

hw.setConfig();
frame = hw.getFrame(1); figure,tabplot; subplot(131), imagesc(frame.z/8); title('z'); subplot(132), imagesc(frame.c);title('c');subplot(133), imagesc(frame.i);title('i');

