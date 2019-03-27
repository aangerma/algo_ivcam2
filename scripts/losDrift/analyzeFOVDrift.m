function [res] = analyzeFOVDrift(sphFrames, worldCapture)

params = Validation.aux.defaultMetricsParams();
params.verbose = true;
params.worldGridFrame = finalWorld.frame;
params.camera = finalWorld.camera;

[score, mResFOV, mDataFOV] = Validation.metrics.losLaserFOVAnglesDrift(sphFrames, params);

nFrames = length(frames);
for i = 1:nFrames
    sphFrames(i).i = fillHolesMM(sphFrames(i).i);
end

[score, mResGrid] = Validation.metrics.losGridDrift(sphFrames, params);

%% graphs over temperature
if (isempty(sphFrames(2).temp))
    return;
end

figure; plot([sphFrames.lddTemp], fovX);
title(sprintf('world X FOV over temperature, drift: %.2f deg',...
    res.changeXFov, res.driftXFov));
ylabel('xFov'); xlabel('Temp');

figure; plot([sphFrames.lddTemp], fovL);
title(sprintf('world Left FOV over temperature, drift: %.2f deg', driftFovL));
ylabel('Left Fov'); xlabel('Temp');

figure; plot([sphFrames.lddTemp], fovR);
title(sprintf('world Right FOV over temperature, drift: %.2f deg', driftFovR));
ylabel('Right Fov'); xlabel('Temp');

figure; plot([sphFrames.lddTemp], fovT);
title(sprintf('world Top FOV over temperature, drift: %.2f deg', driftFovT));
ylabel('Top Fov'); xlabel('Temp');

figure; plot([sphFrames.lddTemp], fovB);
title(sprintf('world Bottom FOV over temperature, drift: %.2f deg', driftFovB));
ylabel('Bottom Fov'); xlabel('Temp');

end
