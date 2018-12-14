
% varargin = struct('config',struct('outputFolder', 'c:\\temp\\valTest\out', 'dataFolder', 'X:\Data\IvCam2\maxRange\testRecords', 'dataSource', 'file'));
% testConfig.maxRange = struct('name', 'debug', 'metrics', 'fillRate', 'target', 'wall_10Reflectivity', 'distance', '260cm');
% [score, out] = Validation.runIQValidation(testConfig, varargin);
d = 'X:\Data\IvCam2\maxRange\testRecords';
files = dir(fullfile(d, '*.mat'));
files = files(2:end);% Ignore camera config for now
metrics = {'fillRate';'zStd'};
target = 'wall_10Reflectivity';
params = Validation.aux.defaultMetricsParams();
params.roi = 0.4;
params.detectDarkRect = 1;



for fi = 1:numel(files)
    file = files(fi);
    if contains(file.name,'LPF_disabled')
       continue; 
    end
    file.name
    load(fullfile(d,file.name));
    
    for metI = 1:2 
        met = @(m,t,p) Validation.metrics.(m)(frames, p);
        [score, res] = met(metrics{metI},target,params);
        if metI == 1
            results.(file.name(1:end-4)).(metrics{metI}) = res.meanFillRate;
        elseif metI == 2
            results.(file.name(1:end-4)).(metrics{metI}) = res.meanTempNoise;
        end
    end
end