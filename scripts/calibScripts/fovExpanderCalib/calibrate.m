
clear
CBParams.size = 30;
CBParams.bsz = [9,13];
fprintff=@(varargin) fprintf(varargin{:});
fnCalib = fullfile('C:\source\algo_ivcam2\scripts\calibScripts\fovExpanderCalib\resultCalib','calib.csv');
fnUndsitLut = fullfile('C:\source\algo_ivcam2\scripts\calibScripts\fovExpanderCalib\resultCalib','FRMWundistModel.bin32');
% fovExpander = xlsread("Expander magnifications.xlsx");
calibParams = xml2structWrapper('calibParams.xml');


%% Take images and then run full calib with and without fov expander
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\scripts\calibScripts\fovExpanderCalib\initConfigCalib');
hw = HWinterface();
regs = fw.get();
fnAlgoInitMWD = 'algoInit.txt';
fw.genMWDcmd('DIGG|DEST',fnAlgoInitMWD);
hw.runPresetScript('maReset');
pause(0.1);
hw.runScript(fnAlgoInitMWD);
pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.shadowUpdate();

% Calibrate DFZ
regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
r=Calibration.RegState(hw);   
r.add('JFILinvBypass',true);
r.add('DESTdepthAsRange',true);
r.add('DIGGsphericalEn',true);
r.set();
nCorners = 9*13;
d(1)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.7 .7 1]));
Calibration.aux.CBTools.checkerboardInfoMessage(d(1),fprintff,nCorners);
d(2)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
Calibration.aux.CBTools.checkerboardInfoMessage(d(2),fprintff,nCorners);
d(3)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.5 .5 1]));
Calibration.aux.CBTools.checkerboardInfoMessage(d(3),fprintff,nCorners);
[dfzRegs,results.geomErr] = calibDFZ(d(1:3),regs,calibParams,fprintff,0);
r.reset();

if(results.geomErr<1.5)
    fw.setRegs(dfzRegs,fnCalib);
    fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
    fnAlgoTmpMWD =  fullfile('C:\source\algo_ivcam2\scripts\calibScripts\fovExpanderCalib\resultCalib','algoValidCalib.txt');
    [regs,luts]=fw.get();%run autogen
    fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
    hw.runScript(fnAlgoTmpMWD);
    hw.shadowUpdate();
else
    fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
end
% Calibrate ROI
% fprintff('[-] Calibrating ROI...\n');
% roiregs = calibROI(hw, regs,calibParams);
% fw.setRegs(roiregs, fnCalib);
% regs = fw.get(); % run bootcalcs
% fnAlgoTmpMWD =  fullfile('C:\source\algo_ivcam2\scripts\calibScripts\fovExpanderCalib\resultCalib','algoROICalib.txt');
% fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
% hw.runScript(fnAlgoTmpMWD);
% hw.shadowUpdate();
% fprintff('[v] Done.\n');

% Calibrate Undist
[udistLUT.FRMW.undistModel,udistRegs,maxPixelDisplacement] = calibUndistAng2xyBugFixWithFE(fw,calibParams);
udistRegs.DIGG.undistBypass = false;
fw.setRegs(udistRegs, fnCalib);
fw.setLut(udistLUT);
[regs,luts] = fw.get(); % run bootcalcs
% Update fnCalin and undist lut in output dir
fw.writeUpdated(fnCalib);
io.writeBin(fnUndsitLut,udistLUT.FRMW.undistModel);

% write to device
fnAlgoTmpMWD =  fullfile('C:\source\algo_ivcam2\scripts\calibScripts\fovExpanderCalib\resultCalib','algoUndistCalib.txt');
fw.genMWDcmd('DEST|DIGG|CBUFspare',fnAlgoTmpMWD);
hw.runScript(fnAlgoTmpMWD);
hw.shadowUpdate();

% Validate
fprintff('Validating... Opening stream...');
frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
Calibration.aux.CBTools.checkerboardInfoMessage(frame,fprintff,nCorners);
fprintff('Done.\n');
Calibration.validation.validateDFZ(hw,frame,fprintff);
