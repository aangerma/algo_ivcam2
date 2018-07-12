path = 'D:\Data\Ivcam2\ES1\Wall80_named';

distDirs = dir(path);
distDirs = distDirs(3:end);

for i = 1:length(distDirs)
    fprintf('%s\n', distDirs(i).name);
    dist(i) = sscanf(distDirs(i).name, '%g');
    framesPath = fullfile(path, distDirs(i).name);
    frames = Validation.aux.readTargetDir([framesPath '\1']);
    [planeFit(i), res] = Validation.metrics.planeFit(frames, params);
    [zStd(i), res] = Validation.metrics.zStd(frames, params);
end

[sDist, si] = sort(dist);
Distances = sDist';
PlaneFit = planeFit(si)';
ZStd = zStd(si)';