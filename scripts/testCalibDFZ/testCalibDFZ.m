function [] = testCalibDFZ()
clear
addpath('D:\worksapce\ivcam2\algo_ivcam2\scripts\calibScripts\DODCalib\DFZSimulator');
fw = Pipe.loadFirmware('D:\worksapce\ivcam2\algo_ivcam2\+Calibration\initConfigCalib');
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
yRotation = [0,0,0];

num_per_scenario = 3;

scenario_1 = [zeros(num_per_scenario,1), zeros(num_per_scenario,1), [500;650;800]]; %Centered
% Moving in x direction
scenario_2 = [zeros(num_per_scenario,1)+120, zeros(num_per_scenario,1), [500;650;800]]; 
scenario_3 = [zeros(num_per_scenario,1)+80, zeros(num_per_scenario,1), [500;650;800]];
scenario_4 = [zeros(num_per_scenario,1)-80, zeros(num_per_scenario,1), [500;650;800]];
scenario_5 = [zeros(num_per_scenario,1)-120, zeros(num_per_scenario,1), [500;650;800]];
%{
% Moving in y direction
scenario_6 = [zeros(num_per_scenario,1), zeros(num_per_scenario,1)+100, [500;650;800]];
scenario_7 = [zeros(num_per_scenario,1), zeros(num_per_scenario,1)+200, [620;750;800]];
scenario_8 = [zeros(num_per_scenario,1), zeros(num_per_scenario,1)-50, [500;650;800]];
scenario_9 = [zeros(num_per_scenario,1), zeros(num_per_scenario,1)-100, [620;750;800]];
%}

% Test:
num_testing_images = 30;
test =	[linspace(-150,350,num_testing_images)', linspace(-100,450,num_testing_images)', repmat(linspace(550,850,15),1,2)';
        linspace(150,-300,num_testing_images)', linspace(-100,450,num_testing_images)', repmat(linspace(550,850,15),1,2)'];


displacement = [scenario_2;scenario_3;scenario_1; scenario_4...
    ;scenario_5];%scenario_6;scenario_7;scenario_8;scenario_9];

num_scenarios = length(displacement)/num_per_scenario;
%%
noiseStdAng = 5;
noiseStdR = 1;


for k1 = 0:num_scenarios-1
    for k2 = 1:num_per_scenario
        [darr(k1*num_per_scenario + k2).rpt,~] = simulateCB(displacement(k1*num_per_scenario + k2,:),yRotation(k2),regs,CBParams,noiseStdAng,noiseStdR);
        % View checerboard in image pixels:
        [x_pix,y_pix] = Calibration.aux.ang2xySF(darr(k1*num_per_scenario + k2).rpt(:,:,2),darr(k1*num_per_scenario + k2).rpt(:,:,3),regs,[],true);
%         figure(151285);
%         tabplot;
%         plot(x_pix,y_pix,'*');
%         axis([0,640,0,480])
    end
end

for k = 1:size(test,1)
        [darr_test(k).rpt,~] = simulateCB(test(k,:),0,regs,CBParams,noiseStdAng,noiseStdR);
        % View checerboard in image pixels:
        [x_pix,y_pix] = Calibration.aux.ang2xySF(darr_test(k).rpt(:,:,2),darr_test(k).rpt(:,:,3),regs,[],true);
%         figure(120784);
%         tabplot;
%         plot(x_pix,y_pix,'*');
%         axis([0,640,0,480])
end

calibParams = xml2structWrapper('calibParams.xml');
minerr = zeros(1,num_scenarios);
minerrDiag = zeros(1,num_scenarios);
counter = 1;
for k1 = 0:num_scenarios-1
    x0 = double([70 56 5000 0 0 0 0 0]);
    [dfzRegs,minerr(counter)] = Calibration.aux.calibDFZ(darr(k1*num_per_scenario+1:k1*num_per_scenario+num_per_scenario),regs,calibParams,@fprintf,0,0,x0);
    x0 = double([dfzRegs.FRMW.xfov dfzRegs.FRMW.yfov dfzRegs.DEST.txFRQpd(1) dfzRegs.FRMW.laserangleH dfzRegs.FRMW.laserangleV 0 0 0]);
    [~,minerrDiag(counter)]=Calibration.aux.calibDFZ(darr_test,regs,calibParams,@fprintf,1,1,x0);
    fprintf('eGeom123=%.3g. eGeom45=%.3g.\n',minerr(counter),minerrDiag(counter));
    counter = counter+1;
end

figure;
plot(1:length(minerr),minerr, 1:length(minerrDiag),minerrDiag);
title('Train on different x locations, test on different locations');
legend('Training eGeom', 'Testing eGeom');
grid minor;

%%
for k = 1:50
    [darr2(k).rpt,~] = simulateCB([0,40,300],0,regs,CBParams,noiseStdAng,noiseStdR);
end
% [darr3.rpt,~] = simulateCB([0,40,700],0,regs,CBParams,noiseStdAng,noiseStdR);

% View checerboard in image pixels:
[x_pix,y_pix] = Calibration.aux.ang2xySF(darr2(1).rpt(:,:,2),darr2(1).rpt(:,:,3),regs,[],true);
figure(151286);
plot(x_pix,y_pix,'*');
axis([0,640,0,480])

calibParams = xml2structWrapper('calibParams.xml');

minerr = zeros(1,num_scenarios);
minerrDiag = zeros(1,num_scenarios);
counter = 1;
for k1 = 0:num_scenarios-1
    x0 = double([70 56 5000 0 0 0 0 0]);
    [dfzRegs,minerr(counter)] = Calibration.aux.calibDFZ(darr(k1*num_per_scenario+1:k1*num_per_scenario+num_per_scenario),regs,calibParams,@fprintf,0,0,x0);
    x0 = double([dfzRegs.FRMW.xfov dfzRegs.FRMW.yfov dfzRegs.DEST.txFRQpd(1) dfzRegs.FRMW.laserangleH dfzRegs.FRMW.laserangleV 0 0 0]);
    [~,minerrDiag(counter)]=Calibration.aux.calibDFZ(darr2,regs,calibParams,@fprintf,1,1,x0);
    fprintf('eGeom123=%.3g. eGeom45=%.3g.\n',minerr(counter),minerrDiag(counter));
    counter = counter+1;
end

figure;
plot(1:length(minerr),minerr, 1:length(minerrDiag),minerrDiag);
title('Train on different x locations, test on checkerboard filling FOV')
legend('Training eGeom', 'Testing eGeom');
grid minor;
end
