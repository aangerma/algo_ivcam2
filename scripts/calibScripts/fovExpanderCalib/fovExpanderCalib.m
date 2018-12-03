% Steps towards fov expander
%{
Method I:
1. Add to ang2xySF a fovx expander factor - either an [M,2] array with M
input angle bins and the relevant expansion factor, or a single value for
all angles. Do the same with xy2angSF.
2. Modify ang2xy bug fix.

Method II:
1. Let DFZ run wild
2. Iterate with undistort (on angx and angy - at the end transform to xy).
Method III:
1. Get Intrinsics from 1 spherical image. Find delay based on the depth.

Validate all methods by capturing 20 images from different angles. Train
with 15 and take the geometric and projection errors on the last 5. (Let
camera run for some time first).


%}
clear
CBParams.size = 30;
CBParams.bsz = [9,13];
fovExpander = xlsread("Expander magnifications.xlsx");

fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
regs.DEST.txFRQpd = single([5050,5050,5050]);
regs.FRMW.xfov = single(65);
regs.FRMW.yfov = single(55);
regs.FRMW.laserangleH = single(0);
regs.FRMW.laserangleV = single(0);
fw.setRegs(regs,'');
regs = fw.get();

dists = 400:100:600;
for i = 1:numel(dists)
    [darr(i).rpt,~] = simulateCB(dists(i),regs,CBParams,fovExpander);
end

fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
regs= fw.get();
% fovExpander = [0:90;0:90]';
[dfzRegs,eGeom,eProj] = calibDFZWithFE(darr,regs,0,fovExpander,1);

%% Take 4 images and then run full calib with and without fov expander
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\scripts\calibScripts\fovExpanderCalib\initConfigCalib');
regs = fw.get();
fnAlgoInitMWD  =  'algoInit.txt';
fw.genMWDcmd('DIGG|DEST',fnAlgoInitMWD);
hw.runPresetScript('maReset');
pause(0.1);
hw.runScript(fnAlgoInitMWD);
pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.shadowUpdate();
fprintff('Done.\n');
regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
r=Calibration.RegState(hw);   
r.add('JFILinvBypass',true);
r.add('DESTdepthAsRange',true);
r.add('DIGGsphericalEn',true);
r.set();


fprintf('Capturing frames without fisheye...');
for i = 1:4
    darr(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.01 .01 1]));
end
fprintf('Done.\n');
fprintf('Capturing frames with fisheye...');
for i = 1:4
    darrFE(i) = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.01 .01 1]));
end
fprintf('Done.\n');

r.reset();
save 'records.mat' 'darrFE' 'darr' 'regs'

%% Run the two calibrations
fovExpander = xlsread("Expander magnifications.xlsx");

[dfzRegs,eGeom(1),eProj(1)] = calibDFZWithFE(darr([1,3,4]),regs,0,[]);
x0 = double([dfzRegs.FRMW.xfov dfzRegs.FRMW.yfov dfzRegs.DEST.txFRQpd(1) dfzRegs.FRMW.laserangleH dfzRegs.FRMW.laserangleV]);
[~,eGeom(2),eProj(2)] = calibDFZWithFE(darr(2),regs,1,[],x0);
[dfzRegsFE,eGeomFE(1),eProjFE(1)] = calibDFZWithFE(darrFE([1,3,4]),regs,0,fovExpander);
x0 = double([dfzRegsFE.FRMW.xfov dfzRegsFE.FRMW.yfov dfzRegsFE.DEST.txFRQpd(1) dfzRegsFE.FRMW.laserangleH dfzRegsFE.FRMW.laserangleV]);
[~,eGeomFE(2),eProjFE(2)] = calibDFZWithFE(darrFE(2),regs,1,fovExpander,x0);



[dfzRegs,undistRegs,undistlut,eGeom(1),eProj(1)] = trainWithFovModel(fw,darrTrain,darrVal,fovExpander);

[eGeom(2),eProj(2)] = trainAltDFZandProj(fw,darrTrain,darrVal);
[eGeom(3),eProj(3)] = trainIntrinsicsPlusDelay(fw,darrTrain,darrVal);