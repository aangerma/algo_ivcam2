


fw=Pipe.loadFirmware('\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
luts.FRMW.undistModel=zeros(2048,1,'uint32');

fw.setLut(luts);
resetregs.JFIL.bypass = false;
resetregs.DIGG.undistBypass=false;
resetregs.DEST.txFRQpd=single([5000 5000 5000]);
resetregs.JFIL.invConfThr = uint8(0); % return to default at the end
fw.setRegs(resetregs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
% fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfig.txt')




%%
hw=HWinterface(fw);
md.z = zeros(480,640,'uint16');
md.i = zeros(480,640,'uint8');
md.c = zeros(480,640,'uint8');
for i = 1:30
    fprintf('%d \n',i)
    d(i) = hw.getFrame();
    md.z = md.z+d(i).z/30;
    md.i = md.i+d(i).i/30;
    md.c = md.c+d(i).c/30;
end
d_.z = zeros(480,640,'uint16');
d_.c = zeros(480,640,'uint8');
d_.i = zeros(480,640,'uint8');
for i=1:30
    d_.z = d_.z+d(i).z/30;
    d_.i = d_.i+d(i).i/30;
    d_.c = d_.c+d(i).c/30;
end


md_.z = zeros(size(md.z),'uint16');
md_.i = zeros(size(md.i),'uint8');
md_.c = zeros(size(md.c),'uint8');
s = 20;
md_.z(:,23+s:640-23+s) = md.z(:,1:595);
md_.i(:,23+s:640-23+s) = md.i(:,1:595);
md_.c(:,23+s:640-23+s) = md.c(:,1:595);
[calibRegs,calibLuts] = Calibration.aux.runDODCalib(md,regs,luts,1);

fw.setLut(calibLuts);
fw.setRegs(calibRegs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfig.txt')

