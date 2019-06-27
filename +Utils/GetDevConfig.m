function [] = GetDevConfig(base_name)
fw = Pipe.loadFirmware('C:\algo\algo_ivcam2\+Calibration\initScript');
hw = HWinterface;


DIGGspare = hw.read('DIGGspare');
currregs.FRMW.xfov = typecast(DIGGspare(2),'single');
currregs.FRMW.yfov = typecast(DIGGspare(3),'single');
currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
DIGGspare06 = hw.read('DIGGspare_006');
DIGGspare07 = hw.read('DIGGspare_007');
currregs.FRMW.marginL = int16(DIGGspare06/2^16);
currregs.FRMW.marginR = int16(mod(DIGGspare06,2^16));
currregs.FRMW.marginT = int16(DIGGspare07/2^16);
currregs.FRMW.marginB = int16(mod(DIGGspare07,2^16));


% Verify version of calibration
unitConfigVersion=hw.read('DIGGspare_000');
unitConfigVersion = typecast(unitConfigVersion,'uint8');
unitConfigVersion = unitConfigVersion(1)+100*unitConfigVersion(2);

fn = [base_name 'config_V' int2str(unitConfigVersion) '.csv'];

fw.setRegs(currregs,fn);
NewRegs = fw.get();
fw.setRegs(NewRegs,fn);
fw.writeUpdated(fn);

%{
[udistlUT.FRMW.undistModel,~,~] = Calibration.Undist.calibUndistAng2xyBugFix(fw);
fw.setLut(udistlUT);
[regs,luts]=fw.get();
%}
end