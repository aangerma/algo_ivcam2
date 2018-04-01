%% Load the current configuration
% fw=Pipe.loadFirmware('\\invcam450\D\data\ivcam20\exp\20180204_MA');
% [regs,luts] = fw.get();
% luts.FRMW.undistModel=typecast(zeros(2048,1,'single'),'uint32');
% resetregs.FRMW.gaurdBandH = single(0.00);
% resetregs.FRMW.gaurdBandV = single(0.05);
% resetregs.JFIL.bypass = false;
% resetregs.DIGG.undistBypass=false;
% resetregs.DEST.txFRQpd=single([5000 5000 5000]);
% resetregs.JFIL.invConfThr = uint8(0); % return to default at the end
% fw.setRegs(resetregs,'');
% fw.setLut(luts);
% [regs,luts] = fw.get();


%% Fw generation of only relevant fields
fw = Firmware;
% Set desired fields:
dodluts.FRMW.undistModel=typecast(zeros(2048,1,'single'),'uint32');
dodregs.FRMW.xfov = single(72);
dodregs.FRMW.yfov = single(56);
dodregs.DEST.txFRQpd = single([5000 5000 5000]);
dodregs.JFIL.invConfThr = uint8(0); 
dodregs.FRMW.gaurdBandH = single(0.00);
dodregs.FRMW.gaurdBandV = single(0.05);
dodregs.FRMW.laserangleH = single(0.00);
dodregs.FRMW.laserangleV = single(0.00);
dodregs.FRMW.xres = uint16(640);
dodregs.FRMW.yres = uint16(480);
dodregs.FRMW.marginL = int16(0);
dodregs.FRMW.marginT = int16(0);
dodregs.FRMW.marginR = int16(0);
dodregs.FRMW.marginB = int16(0);
dodregs.FRMW.xoffset=single(0);
dodregs.FRMW.yoffset=single(0);
dodregs.FRMW.undistXfovFactor=single(1);
dodregs.FRMW.undistYfovFactor=single(1);
dodregs.DIGG.undistBypass = false;
dodregs.GNRL.rangeFinder=false;
dodregs.FRMW.projectionYshear =single(0);
dodregs.FRMW.yflip =single(0);
dodregs.FRMW.xR2L =single(0);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(dodregs);
dodregs = Firmware.mergeRegs( dodregs ,trigoRegs);
diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(dodregs);
dodregs=Firmware.mergeRegs(dodregs,diggRegs);
fw.setLut(dodluts);
io.writeBin('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\dodInitConfigs\FRMWundistModel.bin32',dodluts.FRMW.undistModel)
fw.setRegs(dodregs,'\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\dodInitConfigs\dodInit.csv');
fw.writeUpdated('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\dodInitConfigs\dodInit.csv');

%% Load the FW struct from the csv files, generate MWD with only the relevant regs.
fw=Pipe.loadFirmware('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\dodInitConfigs');
% fw=Pipe.loadFirmware('\\invcam450\D\source\ivcam20\+Calibration\initScript');
[regs,luts] = fw.get();
neededRegsNames = 'DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|FRMWgaurdBandH|FRMWgaurdBandV|FRMWlaserangleH|FRMWlaserangleV|FRMWxfov|FRMWyfov|DIGGundistModel|FRMWundistModel';
fw.genMWDcmd(neededRegsNames,'C:\$WORK\Per_Unit_Config\Current\dodInit.txt')



%% In case the above configuration isn't what configured to the unit, configure it.
fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfig0.txt');
%% Define the HW interface
hw=HWinterface(fw);

% mwd a00d01f4 a00d01f8 00000fff // Depth Shadow update imidiate  all
% blocks
% mwd  fffe382c fffe3830 3F0CCCCD  //dsm vertical shift
% mwd  fffe3830 fffe3834 45610000  //dsm vertical scale
% mwd  fffe3840 fffe3844 3F0CCCCD  //dsm horizontal shift
% mwd  fffe3844 fffe3848 457A0000  //dsm horizontal scale

[~,~,e] = Calibration.aux.runDODCalib(hw,1,1);
% warning('off','FIRMWARE:privUpdate:updateAutogen') % Supress checkerboard warning
% fw.setLut(resDODParams.luts);
% fw.setRegs(resDODParams.regs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
% [regs,luts] = fw.get();
resDODParams2.fw.genMWDcmd(neededRegsNames,'C:\$WORK\Per_Unit_Config\Current\dodFinalNoUndist.txt');


resetregs.FRMW.gaurdBandH = single(0.0125);
resetregs.FRMW.gaurdBandV = single(0.13);c
resetregs.FRMW.marginT = int16(00);
resetregs.FRMW.marginB = int16(00);
resetregs.FRMW.yres = uint16(480);% + resetregs.FRMW.marginT + resetregs.FRMW.marginB);
fw.setRegs(resetregs,'\\invcam450\D\data\ivcam20\exp\20180204_MA');
[regs,luts] = fw.get();
fw.genMWDcmd([],'C:\$WORK\Per_Unit_Config\Current\algoConfigM.txt');

