clear
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initConfigCalib');
baseline = single(0);
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
