function  [valPassed, dbg] = runValidation(valConfig, fprintff)


t=tic;
valPassed = 0; dbg = [];
if(ischar(valConfig))
    valConfig=xml2structWrapper(valConfig);
end

if(~exist('valParams','var') || isempty(valParams))
    %% ::load default configuration
    valConfig = xml2structWrapper('valConfig.xml');
end

if(~exist('fprintff','var'))
    fprintff=@(varargin) fprintf(varargin{:});
end

verbose = valConfig.verbose;
if(exist(valConfig.outputFolder,'dir'))
    if(~isempty(dirFiles(valConfig.outputFolder,'*.bin')))
        fprintff('[x] Error! directory %s is not empty\n',valConfig.outputFolder);
        valPassed = 0;
        return;
    end
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
testTargets = unique(cellfun(@(t)(str2mat(t.target)),tests,'UniformOutput',false));

%% capture frames
targetFrames = cell(length(testTargets),1);
for i=1:length(testTargets)
    iTarget = find(strcmp({targets.target}, testTargets{i}),1);
    targetFrames{i} = Validation.showImageRequest(hw, targets(iTarget));
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
