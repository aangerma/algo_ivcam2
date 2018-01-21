
fw = Firmware('\\invcam450\d\data\ivcam20\exp\20180121_MA\');
%%
hw = hwInterface(fw);
%%
frame = hw.getFrame();
figure(2525232);clf;
tabplot;imagesc(frame.z);
tabplot;imagesc(frame.i);
tabplot;imagesc(frame.c);
drawnow


hw.read('JFILbypass');

regs.JFIL.bypass = true;
fw.setRegs(regs,'.');
hw.write('JFIL');

hw.read('JFILbypass');


frame = hw.getFrame();

tabplot;imagesc(frame.z);
tabplot;imagesc(frame.i);
tabplot;imagesc(frame.c);
