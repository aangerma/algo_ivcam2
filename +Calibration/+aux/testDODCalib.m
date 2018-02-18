%{
1. A function writes the new configuration to IVCAM20Scripts. Write only relevant regs.
2. 30 frames should be taken in the function runDODCalib.
%}
% This script loads the current configuration, 
%% Load the current configuration
fw=Pipe.loadFirmware('\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
luts.FRMW.undistModel=zeros(2048,1,'uint32');
resetregs.JFIL.bypass = false;
resetregs.DIGG.undistBypass=false;
resetregs.DEST.txFRQpd=single([5000 5000 5000]);
resetregs.JFIL.invConfThr = uint8(0); % return to default at the end
fw.setRegs(resetregs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
fw.setLut(luts);
[regs,luts] = fw.get();

% fw.genMWDcmd('undistModel','C:\$WORK\Per_Unit_Config\Current\lutStam.txt')



%% In case the above configuration isn't what configured to the unit, configure it.
fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfig0.txt');
%% Define the HW interface
hw=HWinterface();

% mwd a00d01f4 a00d01f8 00000fff // Depth Shadow update imidiate  all
% blocks
% mwd  fffe382c fffe3830 3F0CCCCD  //dsm vertical shift
% mwd  fffe3830 fffe3834 45610000  //dsm vertical scale
% mwd  fffe3840 fffe3844 3F0CCCCD  //dsm horizontal shift
% mwd  fffe3844 fffe3848 457A0000  //dsm horizontal scale



%%

md.z = zeros(480,640,'uint16');
md.i = zeros(480,640,'uint8');
% md.c = zeros(480,640,'uint8');
for i = 1:30
    fprintf('%d \n',i)
    d(i) = hw.getFrame();
    md.z = md.z+d(i).z/30;
    md.i = md.i+d(i).i/30;
%     md.c = md.c+d(i).c/30;
end



[calibRegs,calibLuts,score] = Calibration.aux.runDODCalib(md,regs,luts,1);

fw.setLut(calibLuts);
fw.setRegs(calibRegs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfig1.txt');


resetregs.FRMW.marginL = int16(10);
resetregs.FRMW.marginR = int16(10);
resetregs.FRMW.xres = uint16(640 + resetregs.FRMW.marginL + resetregs.FRMW.marginR);
fw.setRegs(resetregs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfigM.txt');

