function  [valPassed, dbg] = runValidation(valConfig, fprintff)


t=tic;
valPassed = 0; dbg = [];

if (~exist('valConfig','var') || isempty(valConfig))
    %% ::load default configuration
    fnValConfig = fullfile(fileparts(mfilename('fullpath')),filesep,'valConfig.xml');
    if (exist(fnValConfig,'file'))
        valConfig = xml2structWrapper(fnValConfig);
    else
        valConfig.verbose = true;
        valConfig.outputFolder = 'c:\temp\valTest';
        valConfig.internalFolder = 'internal';
        valConfig.saveTargets = true;
    end
end

verbose = valConfig.verbose;

mkdirSafe(valConfig.outputFolder);
dirInternal = fullfile(valConfig.outputFolder, valConfig.internalFolder);
mkdirSafe(dirInternal);

if(~exist('fprintff','var'))
    fprintff=@(varargin) fprintf(varargin{:});
end

targets = cell2mat(struct2cell(xml2structWrapper('targets.xml')));
targetPath = fullfile(fileparts(mfilename('fullpath')),filesep,'targets',filesep);
for i=1:length(targets)
    targets(i).img = imread([targetPath targets(i).imgFile]);
    if ~isfield(targets(i), 'tForm') || isempty(targets(i).tForm)
        targets(i).tForm = diag([.7 .7 1]);
    end
end

%% find all the targets needed for the tests
tests = (struct2cell(xml2structWrapper('tests.xml')));
% skip first struct
tests = tests(2:end);
testTargets = unique(cellfun(@(t)(str2mat(t.target)),tests,'UniformOutput',false));

%% init camera
%hw = HWinterface;
hw = [];

%% capture frames
targetFrames = cell(length(testTargets),1);
for i=1:length(testTargets)
    iTarget = find(strcmp({targets.target}, testTargets{i}),1);
    t = targets(iTarget);
    fnTarget = fullfile(dirInternal, [t.target '.mat']);
    if (exist(fnTarget,'file'))
        targetFrames{i} = load(fnTarget);
    else
        frames = Validation.showImageRequest(hw, t);
        save(fnTarget, 'frames');
        targetFrames{i} = frames;
    end
        
end

%% read camera config
if (~isempty(hw))
    cameraConfig.K = reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
else
    cameraConfig.K = diag([1 1 1]);
end


%% run tests
for i=1:length(tests)
    iTarget = find(strcmp(testTargets, tests{i}.target),1);
    runTest(tests{i}.metrics, targetFrames{iTarget}, valConfig, cameraConfig);
end

results = struct;

end

function [score, res] = runTest(metrics, frames, valConfig, cameraConfig)

switch metrics
    case 'fillRate'
        [score, res] = Validation.metrics.fillRate(frames);
    case 'interDist7x7x50'
        params.squareSize = 50;
        params.K = cameraConfig.K;
        [score, res] = Validation.metrics.fillRate(frames, params);
    otherwise
        error('Validation:runValidation', 'unknown metrics ''%s\''', metrics);
end

end
