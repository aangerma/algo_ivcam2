% My personal script for calibration new units - affect only DEST-DIGG
outputFolder = 'C:\temp\0121_0423';
outputFolderFWFiles = 'C:\temp\0121_0423\calib';
doInit = 1;
fprintff = @fprintf;
verbose = 1;
uniformProjection = 0; % If 1 - "eye safe". If 0 - constant laser power.

internalFolder = fullfile(outputFolder,filesep,'AlgoInternal');
fnCalib     = fullfile(internalFolder,filesep,'calib.csv');
fnUndsitLut = fullfile(internalFolder,filesep,'FRMWundistModel.bin32');
initFldr = fullfile('\\tmund-MOBL1\C$\source\algo_ivcam2\+Calibration','initConfigCalib');
copyfile(fullfile(initFldr,filesep,'*.csv'),internalFolder)

mkdirSafe(outputFolder);
mkdirSafe(internalFolder);
mkdirSafe(outputFolderFWFiles);

fprintff('Loading Firmware...');
fw = Pipe.loadFirmware(internalFolder);
fprintff('Done\n');

fprintff('Loading HW interface...');
hw=HWinterface(fw);
fprintff('Done\n');
[regs,luts]=fw.get();%run autogen

if(doInit)  
    fnAlgoInitMWD  =  fullfile(internalFolder,filesep,'algoInit.txt');
    fw.genMWDcmd('DEST|DIGG',fnAlgoInitMWD);
    fprintff('init...');
    hw.runScript(fnAlgoInitMWD);
    hw.shadowUpdate();
    fprintff('Done.\n');
end
hw.runPresetScript('startStream');

if(uniformProjection)
    hw.cmd('Iwb e2 03 01 93');
else
    hw.cmd('Iwb e2 03 01 13');% Laser is constant
    hw.cmd('Iwb e2 08 01 ff');% Adjust laser power
end
hw.shadowUpdate();

%% ::calibrate delays:: 
% No need currently, it looks pretty good on startup.

%% 
fprintff('FOV, System Delay, Zenith and Distortion calibration...\n');


regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
hw.setReg('JFILinvBypass',true);
hw.setReg('DESTdepthAsRange',true);
hw.setReg('DIGGsphericalEn',true);
hw.shadowUpdate();

d(1)=showImageRequestDialog(hw,1,diag([.7 .7 1]));
d(2)=showImageRequestDialog(hw,1,diag([.6 .6 1]));
d(3)=showImageRequestDialog(hw,1,diag([.5 .5 1]));

[dodregs,results.geomErr] = Calibration.aux.calibDFZ(d(1:3),regs,verbose);
hw.setReg('DESTdepthAsRange',false);
hw.setReg('DIGGsphericalEn',false);
hw.shadowUpdate();

fw.setRegs(dodregs,fnCalib);


if(results.geomErr<1.5)
    fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
else
    fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
end


fprintff('Validating...\n');
%validate

fnAlgoTmpMWD =  fullfile(internalFolder,filesep,'algoValidCalib.txt');
[regs,luts]=fw.get();%run autogen
fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
hw.runScript(fnAlgoTmpMWD);
hw.shadowUpdate();
d=hw.getFrame(30);
[~,results.geomErrVal] = Calibration.aux.calibDFZ(d,regs,verbose,true);

if(results.geomErrVal<1.5)
    fprintff('[v] geom valid passed[e=%g]\n Writing DOD regs.\n',results.geomErrVal);
    fw.writeUpdated(fnCalib);
else
    fprintff('[x] geom valid failed[e=%g]\n',results.geomErrVal);
end



fw.writeFirmwareFiles(outputFolderFWFiles)
hw.cmd(strcat('WrCalibData "',fullfile(outputFolderFWFiles,'Algo_Pipe_Calibration_VGA_CalibData_Ver_01_01.txt"')));% Writes the DOD calib to EPROM
hw.runPresetScript('stopStream');