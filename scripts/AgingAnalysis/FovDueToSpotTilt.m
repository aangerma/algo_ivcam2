close all
clear all
clc

%

fw = Firmware;
regs = fw.get();
regs.FRMW.fovexExistenceFlag = true;

xHalfFov = 30;
yHalfFov = 25;
tiltErr = 0:0.1:2;

inVecOrig = [sind(-xHalfFov),0,cosd(-xHalfFov); sind(xHalfFov),0,cosd(xHalfFov)];
outVecOrig = Calibration.aux.applyFOVex( inVecOrig, regs );
xFovOrig = diff(atan2d(outVecOrig(:,1), outVecOrig(:,3)));

for k = 1:length(tiltErr)
    inVecErr = [sind(-xHalfFov+tiltErr(k)),0,cosd(-xHalfFov+tiltErr(k)); sind(xHalfFov+tiltErr(k)),0,cosd(xHalfFov+tiltErr(k))];
    outVecErr = Calibration.aux.applyFOVex( inVecErr, regs );
    xFovErr(k) = diff(atan2d(outVecErr(:,1), outVecErr(:,3)));
end

inVecOrig = [0,sind(-yHalfFov),cosd(-yHalfFov); 0,sind(yHalfFov),cosd(yHalfFov)];
outVecOrig = Calibration.aux.applyFOVex( inVecOrig, regs );
yFovOrig = diff(atan2d(outVecOrig(:,2), outVecOrig(:,3)));

for k = 1:length(tiltErr)
    inVecErr = [0,sind(-yHalfFov+tiltErr(k)),cosd(-yHalfFov+tiltErr(k)); 0,sind(yHalfFov+tiltErr(k)),cosd(yHalfFov+tiltErr(k))];
    outVecErr = Calibration.aux.applyFOVex( inVecErr, regs );
    yFovErr(k) = diff(atan2d(outVecErr(:,2), outVecErr(:,3)));
end

figure
hold on
plot(tiltErr, xFovErr-xFovOrig, '-o')
plot(tiltErr, yFovErr-yFovOrig, '-o')
grid on, xlabel('Spot tilt error [deg]'), ylabel('FOV error'), legend('x','y')
