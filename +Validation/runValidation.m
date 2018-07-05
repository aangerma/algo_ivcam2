function  [valPassed, dbg] = runValidation(runParams, valParams, fprintff)


t=tic;
valPassed = 0; dbg = [];
if(ischar(runParams))
    runParams=xml2structWrapper(runParams);
end

if(~exist('valParams','var') || isempty(valParams))
    %% ::load default configuration
    valParams = xml2structWrapper('valParams.xml');
end

if(~exist('fprintff','var'))
    fprintff=@(varargin) fprintf(varargin{:});
end

verbose = runParams.verbose;
if(exist(runParams.outputFolder,'dir'))
    if(~isempty(dirFiles(runParams.outputFolder,'*.bin')))
        fprintff('[x] Error! directory %s is not empty\n',runParams.outputFolder);
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

%% run tests
for i=1:length(tests)
    iTarget = find(strcmp(testTargets, tests{i}.target),1);
    runTest(tests{i}.metrics, targetFrames{iTarget});
end

results = struct;

end
