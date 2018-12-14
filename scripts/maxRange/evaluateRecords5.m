load('\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\maxRange\testRecord5\scene_frame_52.mat');
imagesc(frame.z/8,[3500,4200]);
BWMask = roipoly();
% varargin = struct('config',struct('outputFolder', 'c:\\temp\\valTest\out', 'dataFolder', 'X:\Data\IvCam2\maxRange\testRecords', 'dataSource', 'file'));
% testConfig.maxRange = struct('name', 'debug', 'metrics', 'fillRate', 'target', 'wall_10Reflectivity', 'distance', '260cm');
% [score, out] = Validation.runIQValidation(testConfig, varargin);
d = '\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\maxRange\testRecord5';
files = dir(fullfile(d, '*.mat'));

metrics = {'fillRate';'zStd'};
target = 'wall_10Reflectivity';
params = Validation.aux.defaultMetricsParams();
params.roi = 0.4;
params.detectDarkRect = 0;
params.BWMask = BWMask;
relevantFilesI = [];
for fi = 1:numel(files)
    file = files(fi);
    if isempty(strfind(file.name,'scene_frame' ))
        relevantFilesI = [relevantFilesI;fi];
    end
end
files = files(relevantFilesI);
for fi = 1:numel(files)
    file = files(fi);
%     fn = file.name(7:end);
    x = load(fullfile(d,file.name));
    variable= fieldnames(x);
    frames = x.(variable{1});
        
    
    params.stdTh = [30,70];
    params.diffFromMeanTh = [30,70];
    [~, tmpresults] = Validation.metrics.maxRange( frames, params );
    tmpresults.name = file.name(1:end-4);
%     figure(2); subplot(3,4,fi); histogram(zSTD,0:5:1000);title(results(fi).name);axis([0,1000,0,500]);
    results(fi) = tmpresults;
end

T = struct2table(results)