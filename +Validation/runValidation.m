function  out = runValidation(testNames, varargin)
    % testName: string array of test names, if empty test will fail
    % Run validation tests
    % config:
    %  sourceFilesPath: string
    %  verbose: bool
    %  outputFolder: string
    %  picturesFolder: string

    % set config params
    p = inputParser;
    addRequired(p, 'testNames', @(x) ~isempty(x))
    addParameter(p, 'config', struct())
    parse(p, testNames, varargin{:})
    config = checkConfig(p.Results.config);

    if ~exist('testNames','var') || isempty(testNames)
        ME = MException('Validation:testsName', 'No tests where specified');
        throw(ME);
    end

    dataFullPath = createOutFolder(config);

    % get test list
    testList = getTestList(config.testFilePath,testNames);

    % prepare target list
    requierdTargets = {testList.target};
    testTargets = getTargets(config.fullTargetListPath, requierdTargets, config.targetFilesPath );

    % get pictures
    [testTargets, cameraConfig] = captureFrames(config.dataSource, testTargets, dataFullPath);

    % run tests
    for iTest=1:length(testList)
        iTarget = testTargets(strcmp({testTargets.target}, testList(iTest).target));
        [~,out.(testList(iTest).name)] = runTest(testList(iTest).metrics, iTarget, cameraConfig);
    end
    
    testOut = fieldnames(out)
    for i=1:length(testOut)
        out.(cell2str(testOut(1)))
    end
 end

function [score, res] = runTest(metrics, target, cameraConfig)
    params = Validation.aux.defaultMetricsParams;
    params.cameraConfig = cameraConfig;
    params.targetConfig=target.params;
    met = @(m,t,p) Validation.metrics.(m)(t.frames, p);
    [score, res] = met(metrics,target,params);
end

function [config] = checkConfig(config)
    if ~isstruct(config)
        config=struct();
    end
    if ~isfield(config, 'outputFolder')
        config.outputFolder = 'c:\temp\valTest';
    end
    if ~isfield(config, 'dataFolder')
        config.dataFolder = 'data';
    end
    if ~isfield(config, 'dataSource')
        config.dataSource = 'HW';
    end
    if ~isfield(config, 'testFilePath')
        config.testFilePath = fullfile(fileparts(mfilename('fullpath')), 'tests.xml');
    end
    if ~isfield(config, 'fullTargetListPath')
        config.fullTargetListPath = fullfile(fileparts(mfilename('fullpath')), 'targets.xml');
    end
    if ~isfield(config, 'targetFilesPath')
        config.targetFilesPath = fullfile(fileparts(mfilename('fullpath')), 'targets', filesep);
    end
end

function dataFullPath = createOutFolder(config)
    mkdirSafe(config.outputFolder);
    dataFullPath = fullfile(config.outputFolder, config.dataFolder);
    mkdirSafe(dataFullPath);
end

function testList = getTestList(testFilePath,testNames)
    fullTestList = xml2structWrapper(testFilePath);
    removeTests = rmfield(fullTestList,testNames);
    testList = rmfield(fullTestList, fields(removeTests));
    testList = cellfun(@(c)(setfield(testList.(c),'name',c)), fieldnames(testList),'uni', false);
    if length(testList)~=length(testNames)
        ME = MException('Validation:getTestList', sprintf('number of tests after filter (%d) dosent mach requested tests (%d)',length(testList),length(testNames)));
        throw(ME)
    end
    testList = cell2mat(testList);
end

function testTargets = getTargets(fullTargetListPath, requierdTargets,targetFilesPath )
    fullTargetsList = xml2structWrapper(fullTargetListPath);
    removeTargets = rmfield(fullTargetsList,requierdTargets);
    testTargets = rmfield(fullTargetsList, fields(removeTargets));
    testTargets = cell2mat(struct2cell(testTargets));
    
    for i=1:length(testTargets)
        testTargets(i).img = imread([targetFilesPath testTargets(i).imgFile]);
        if ~isfield(testTargets(i), 'tForm') || isempty(testTargets(i).tForm)
            testTargets(i).tForm = diag([.7 .7 1]);
        end
    end
end

function [testTargets,cameraConfig] = captureFrames(dataSource, testTargets, dataFullPath);
    % camera config    
    fnCameraConfig = fullfile(dataFullPath, ['cameraConfig.mat']);
    switch dataSource
        case 'HW'
            hw = HWinterface;
            cameraConfig.K = reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
            save(fnCameraConfig, 'cameraConfig');
        case 'file'
            if ~exist(fnCameraConfig, 'file')
                ME = MException('Validation:captureFramse:cameraConfig', sprintf('missing camera confg file: %s', fnCameraConfig));
                throw(ME)
            else
                cameraConfig = load(fnCameraConfig);
            end
        otherwise
            ME = MException('Validation:captureFramse', sprintf('%s option not supported', dataSource));
            throw(ME)
    end
    
    % capture frames
    for i=1:length(testTargets)
        fnTarget = fullfile(dataFullPath, [testTargets(i).target, '.mat']);
        switch dataSource
            case 'file'
                if ~exist(fnTarget,'file')
                    ME = MException('Validation:captureFramse:file', sprintf('file dosent exist: %s', fnTarget));
                    throw(ME)
                end
                imgFrames = load(fnTarget);
                testTargets(i).frames = imgFrames.frames;
            case 'HW'
                frames = Validation.showImageRequest(hw, testTargets(i));
                save(fnTarget, 'frames');
                testTargets(i).frames = frames;
            case 'PG'
                ME = MException('Validation:captureFramse:PG', sprintf('%s option not supported', dataSource));
                throw(ME)
        end
    end
end