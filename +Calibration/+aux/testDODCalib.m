


fw=Pipe.loadFirmware('\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
luts.FRMW.undistModel=zeros(2048,1,'uint32');

fw.setLut(luts);
resetregs.DIGG.undistBypass=false;
resetregs.DEST.txFRQpd=single([0 0 0]);
resetregs.JFIL.invConfThr = uint8(0); % return to default at the end
fw.setRegs(resetregs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
% fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfig.txt')

%%
hw=HWinterface();
md.z = zeros(480,640,'uint16');
md.i = zeros(480,640,'uint8');
md.c = zeros(480,640,'uint8');
for i = 1:30
    
    d(i) = hw.getFrame();
    md.z = md.z+d(i).z/30;
    md.i = md.i+d(i).i/30;
    md.c = md.c+d(i).c/30;
end

[calibRegs,calibLuts] = Calibration.aux.runDODCalib(md,regs,luts,1);