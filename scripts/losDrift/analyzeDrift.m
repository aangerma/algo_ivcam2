function [res] = analyzeDrift(sFrames,regsSph,wCap)

nFrames = length(sFrames);
for i = 1:nFrames
    sFrames(i).i = fillInternalHolesMM(sFrames(i).i);
end

params = Validation.aux.defaultMetricsParams();
params.verbose = true;
[score, mResFOC] = Validation.metrics.losLaserFOVDrift(sFrames, params);

[score, mResGrid] = Validation.metrics.losGridDrift(sFrames, params);

%% world frame
wFrame = wCap.frame;
figure; imagesc(wFrame.i);
[points, gridSize] = Validation.aux.findCheckerboard(wFrame.i);
hold on; plot(points(:,1),points(:,2),'+r');

v = Validation.aux.pointsToVertices(points, wFrame.z, wCap.camera);
[wAngX,wAngY] = vertices2worldAngles(v, wCap.regs);
figure; plot(wAngX,wAngY, '.-'); title('world angles from the checkeckboard');

for i = 1:nFrames
    irSph = sFrames(i).i;
    [ptsSph, gridSizeSph] = Validation.aux.findCheckerboard(irSph);
    figure(118); imagesc(irSph); hold on; plot(ptsSph(:,1),ptsSph(:,2),'+r');
    title(sprintf('frame %u of %u', i, nFrames));

    FwAngX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),wAngX);
    FwAngY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),wAngY);

    fovL(i) = FwAngX(mResFOC.fovL(i), mResFOC.yCenter);
    fovR(i) = FwAngX(mResFOC.fovR(i), mResFOC.yCenter);
    
    fovT(i) = FwAngX(mResFOC.xCenter, mResFOC.fovT(i));
    fovB(i) = FwAngX(mResFOC.xCenter, mResFOC.fovB(i));
end

xFov = fovR - fovL;
figure; plot([sFrames.lddTemp], xFov);
title('real world X FOV over temperature');
ylabel('xFov'); xlabel('Temp');

figure; plot([sFrames.lddTemp], fovL);
title('real world Left FOV over temperature');
ylabel('Left Fov'); xlabel('Temp');

figure; plot([sFrames.lddTemp], fovR);
title('real world Right FOV over temperature');
ylabel('Right Fov'); xlabel('Temp');

