clear
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
baseline = single(31);
regs.DEST.baseline = baseline;
regs.FRMW.laserangleH = single(0.05);
regs.FRMW.laserangleV = single(0.05);
regs.DEST.txFRQpd = single([5100 5000 5000]);
regs.FRMW.xfov = single(65);
regs.FRMW.yfov = single(45);
fw.setRegs(regs,'');
[regs,luts] = fw.get();

CBParams.size = 30;
CBParams.bsz = [9,13];
yRotation = [0,0,0,25,-25];
dist = [500,650,800,700,700];
%%
noiseStdAng = 5;
noiseStdR = 1;
for i = 1:5
    [darr(i).rpt,~] = simulateCB(dist(i),yRotation(i),regs,CBParams,noiseStdAng,noiseStdR);
end
calibParams = xml2structWrapper('calibParams.xml');
x0 = double([70 56 5000 0 0 0 0 0]);
for flipBaseline = 0:1
    fprintf(newline);
    [dfzRegs,minerr]=calibDFZ(darr(1:3),regs,calibParams,@fprintf,0,0,x0,flipBaseline);
    x0 = double([dfzRegs.FRMW.xfov dfzRegs.FRMW.yfov dfzRegs.DEST.txFRQpd(1) dfzRegs.FRMW.laserangleH dfzRegs.FRMW.laserangleV 0 0 0]);
    [~,minerrDiag]=calibDFZ(darr(4:5),regs,calibParams,@fprintf,1,1,[],flipBaseline);
    fprintf('eGeom123=%.2g. eGeom45=%.2g.\n',minerr,minerrDiag);
end


%%
% Show that the error doesn't change under zenith and shift in DSM
% In addition, show the xy image of the corners for each pair of zenith and
% offset
for zenith = -15:15
    regs2.FRMW.laserangleH = single(zenith);
    fw.setRegs(regs2,'');
    [regs,luts] = fw.get();
    % [~,minerr]=calibDFZFromRPT(rpt,regs,1,0);
    rptShift = rpt; rptShift(:,:,2) = rptShift(:,:,2) + zenith/(regs.FRMW.xfov/4)*2047;
    [~,minerr]=calibDFZFromRPT(rptShift,regs,1,1);
    [x,y] = Calibration.aux.ang2xySF(rptShift(:,:,2),rptShift(:,:,3),regs,1);
    tabplot;
    plot(x,y,'*');
    title(sprintf('%2f',minerr));
    axis([0,640,0,480])
end


%%
clear
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
baseline = single(30);
regs.DEST.baseline = baseline;
fw.setRegs(regs,'');
[regs,luts] = fw.get();

CBParams.size = 30;
CBParams.bsz = [9,13];
dist = 500;
[rpt,cbxyz] = simulateCB(dist,regs,CBParams);
[~,minerr]=calibDFZFromRPT(rpt,regs,1,0);

% Show that the error doesn't change under zenith and shift in DSM
% In addition, show the xy image of the corners for each pair of zenith and
% offset
i = 1;
for zenith = -15:15
    regs2.FRMW.laserangleH = single(zenith);
    fw.setRegs(regs2,'');
    [regs,luts] = fw.get();
    % [~,minerr]=calibDFZFromRPT(rpt,regs,1,0);
    rptShift = rpt; rptShift(:,:,2) = rptShift(:,:,2) + zenith/(regs.FRMW.xfov/4)*2047;
    [~,minerr(i)]=calibDFZFromRPT(rptShift,regs,1,1);
    [x,y] = Calibration.aux.ang2xySF(rptShift(:,:,2),rptShift(:,:,3),regs,1);
    tabplot;
    plot(x,y,'*');
    title(sprintf('zenith = %d, e=%2f',zenith,minerr));
    axis([0,640,0,480])
    i = i+1;
end
plot(zenith,minerr);

%% Next question - what happens in our case where the baseline has an angle of 2 degrees? What happens to the DFZ calibration?
clear
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
% baseline = single(31);
% fovx = single(65);
% fovy = single(55);
% txDelay = single(5050);
% regs.DEST.baseline = baseline;
% regs.FRMW.xfov = fovx;
% regs.FRMW.yfov = fovy;
% regs.DEST.txFRQpd = [txDelay, txDelay, txDelay];
% fw.setRegs(regs,'');
[regs,luts] = fw.get();

CBParams.size = 30;
CBParams.bsz = [9,13];
dist = 500;
[rpt,cbxyz] = simulateCB(dist,regs,CBParams);
[o,minerr]=calibDFZFromRPT(rpt,regs,1,0);


fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
% baseline = single(31);
% regs2.DEST.baseline = baseline;
% fw.setRegs(regs2,'');
% [regs,luts] = fw.get();

rptShift = rpt; rptShift(:,:,2) = rptShift(:,:,2) - 2/(regs.FRMW.xfov/4)*2047;
[~,minerr]=calibDFZFromRPT(rptShift,regs,1,0);
