function [  ] = setHalfRes( hw ,x1y0)
%SETHALFRES halve the inner vertical resolution os the image wihtin the
%pipe. Output image is resized to the original size.
fileDir = fileparts(mfilename('fullpath'));
fwdir = fullfile(fileDir,'..','..','+Calibration','initScript');
fw = Pipe.loadFirmware(fwdir);
currregs.GNRL.imgHsize = uint16(hw.read('imgHsize'));
currregs.GNRL.imgVsize = uint16(hw.read('imgVsize'));

currregs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
currregs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
currregs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
currregs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single'); 
currregs.EXTL.conLocDelaySlow = hw.read('EXTLconLocDelaySlow');
currregs.EXTL.conLocDelayFastC = hw.read('EXTLconLocDelayFastC');
currregs.EXTL.conLocDelayFastF = hw.read('EXTLconLocDelayFastF');
DIGGspare = hw.read('DIGGspare');
currregs.FRMW.xfov = typecast(DIGGspare(2),'single');
currregs.FRMW.yfov = typecast(DIGGspare(3),'single');
currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
currregs.DEST.txFRQpd = typecast(hw.read('DESTtxFRQpd'),'single')';
DIGGspare06 = hw.read('DIGGspare_006');
DIGGspare07 = hw.read('DIGGspare_007');
currregs.FRMW.marginL = int16(DIGGspare06/2^16);
currregs.FRMW.marginR = int16(mod(DIGGspare06,2^16));
currregs.FRMW.marginT = int16(DIGGspare07/2^16);
currregs.FRMW.marginB = int16(mod(DIGGspare07,2^16));    
fw.setRegs(currregs,'');
regs = fw.get();
if ~regs.JFIL.upscalexyBypass
    fprintf('Half res is already in use. Skipping...\n');
    return 
end

% fw.genMWDcmd('^(?!MTLB|EPTG|FRMW|EXTLauxShadow.*$).*','fo.txt');
if x1y0==0
    newregs.GNRL.imgVsize = regs.GNRL.imgVsize/2;
else
    newregs.GNRL.imgHsize = regs.GNRL.imgHsize/2;
end
newregs.JFIL.upscalex1y0 = x1y0;
newregs.JFIL.upscalexyBypass = 0;
newregs.FRMW.marginT = regs.FRMW.marginT/2;
newregs.FRMW.marginB = regs.FRMW.marginB/2;
newregs.FRMW.marginL = regs.FRMW.marginL/2;
newregs.FRMW.marginR = regs.FRMW.marginR/2;
newregs.DIGG.undistBypass = 1;
newregs.DIGG.sphericalEn = 1;
fw.setRegs(newregs,'');
calibParams.fovExpander.valid = 0;
[udistlUT.FRMW.undistModel,~,~] = Calibration.Undist.calibUndistAng2xyBugFix(fw,calibParams);
fw.setLut(udistlUT);
fw.get();
scname = strcat(tempname,'.txt');
fw.genMWDcmd('^(?!MTLB|EPTG|FRMW|EXTLauxShadow.*$).*',scname);

hw.runPresetScript('maReset');
pause(0.1);
hw.runScript(scname);
pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.runPresetScript('maReset');
hw.runPresetScript('maRestart');
%         hw.cmd('mwd a00d01ec a00d01f0 00000001 // EXTLauxShadowUpdateFrame');
hw.shadowUpdate();



end

