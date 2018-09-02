function  [score, out] = runIQValidation(testConfig, varargin)
    % Run validation tests
    % testConfig: struct for test defenition:
    %  name: (string), test name
    %  metrics: (string), metrics to run on target
    %  target: (string), target name from target xml
    %  distance: (string), distance form target
    %  example: testConfig.minRange = struct('name', 'minRange', 'metrics', 'fillRate', 'target', 'wall_80Reflective', 'distance', '20cm')
    % config:
    %  outputFolder: (string), defult: c:\temp\valTest
    %  dataFolder: (string), defult: data
    %  dataSource: (string), defult: HW, options: HW/file/ivs
    %  fullTargetListPath: (string), reletive file path + targets.xml
    %  targetFilesPath: (string), reletive file path + targets
    %  example: varargin = {struct('config',struct('outputFolder', 'c:\\temp\\valTest', 'dataFolder', 'c:\\temp\\valTest\\data', 'dataSource', 'HW'))}

    
    varargin = {struct('config',struct('outputFolder', 'c:\\temp\\valTest', 'dataFolder', 'X:\Avv\sources\ivs\gen1', 'dataSource', 'ivs'))}
    testConfig.minRange = struct('name', 'minRange', 'metrics', 'fillRate', 'target', 'wall_80Reflectivity', 'distance', '50cm')
    
    % set config params
    p = inputParser;
    addRequired(p, 'testConfig', @(x) ~isempty(x))
    addParameter(p, 'config', struct())
    parse(p, testConfig, varargin{:})
    config = checkConfig(p.Results.config);

    if ~exist('testConfig','var') || isempty(testConfig)
        ME = MException('Validation:testConfig', 'No tests where specified');
        throw(ME);
    end

    dataFullPath = createOutFolder(config);

    % prepare target list
    tests = struct2array(testConfig);
    
    requierdTargets = struct();
    for i=1:length(tests)
        n = strcat(tests(i).target, '_', tests(i).distance);
        v = struct('target', tests(i).target, 'distance', tests(i).distance);
        tests(i).targetName = n;
        requierdTargets.(n)=v;
    end
    testTargets = getTargets(config.fullTargetListPath, requierdTargets, config.targetFilesPath );

    % get pictures
    [testTargets, cameraConfig] = captureFrames(config.dataSource, testTargets, dataFullPath);

    % run tests
    for iTest=1:length(tests)
        try
            iTarget = testTargets(strcmp({testTargets.name}, tests(iTest).targetName));
            [score.(tests(iTest).name),out.(tests(iTest).name)] = runTest(tests(iTest).metrics, iTarget, cameraConfig);
        catch e
            score.(tests(iTest).name) = struct('identifier', e.identifier, 'massage', e.message);
            out.(tests(iTest).name) = struct('identifier', e.identifier, 'massage', e.message);
        end
    end
    
    testOut = fieldnames(out);
    for i=1:length(testOut)
        testOut(i)
        out.(cell2str(testOut(i)))
        score.(cell2str(testOut(i)))
    end
 end

function [score, res] = runTest(metrics, target, cameraConfig)
    params = Validation.aux.defaultMetricsParams;
    params.verbose = false;
    params.camera = cameraConfig;
    params.target = target.params;
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
    if ~isfield(config, 'fullTargetListPath')
        config.fullTargetListPath = fullfile(fileparts(mfilename('fullpath')), 'targets.xml');
    end
    if ~isfield(config, 'targetFilesPath')
        config.targetFilesPath = fullfile(fileparts(mfilename('fullpath')), 'targets', filesep);
    end
end

function dataFullPath = createOutFolder(config)
    mkdirSafe(config.outputFolder);
    dataFullPath = config.dataFolder;
    mkdirSafe(dataFullPath);
end

function targets = getTargets(fullTargetListPath, requierdTargets,targetFilesPath )
    fullTargetsList = xml2structWrapper(fullTargetListPath);
    targets = struct2array(requierdTargets);
    names = fieldnames(requierdTargets);
    for i=1:length(targets)
        targets(i).name = cell2str(names(i));
        targets(i).params = checkTargetParams(fullTargetsList.(targets(i).target).params);
        targets(i).title = ['Place ', fullTargetsList.(targets(i).target).title, ' at ', targets(i).distance];
        targets(i).img=[];
        if ~isempty(fullTargetsList.(targets(i).target).imgFile)
            targets(i).img = imread([targetFilesPath fullTargetsList.(targets(i).target).imgFile]);
        end
    end
end

function [params] = checkTargetParams(params)
    if ~isstruct(params)
        params=struct();
    end
    if ~isfield(params, 'tForm')
        params.tForm = diag([.7 .7 1]);
    end
    if ~isfield(params, 'nFrames')
        params.nFrames = 100;
    end
    if ~isfield(params, 'delay')
        params.delay = 0;
    end
end

function [testTargets,cameraConfig] = captureFrames(dataSource, testTargets, dataFullPath)
    % camera config    
    fnCameraConfig = fullfile(dataFullPath, ['cameraConfig.mat']);
    switch dataSource
        case 'HW'
            hw = HWinterface;
            cameraConfig.K = reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
            save(fnCameraConfig, 'cameraConfig');
        case {'file', 'ivs'}
            if ~exist(fnCameraConfig, 'file')
                ME = MException('Validation:captureFramse:cameraConfig', sprintf('missing camera confg file: %s', fnCameraConfig));
                throw(ME)
            else
                % load camera config
                load(fnCameraConfig);
            end
        otherwise
            ME = MException('Validation:captureFramse', sprintf('%s option not supported', dataSource));
            throw(ME)
    end
    
    % capture frames
    for i=1:length(testTargets)
        fnTarget = fullfile(dataFullPath, [cell2str(testTargets(i).name), '.mat']);
        switch dataSource
            case 'HW'
                frames = Validation.showImageRequest(hw, testTargets(i),testTargets(i).params.nFrames, testTargets(i).params.delay);
                save(fnTarget, 'frames');
                testTargets(i).frames = frames;
            case 'file'
                if ~exist(fnTarget,'file')
                    ME = MException('Validation:captureFramse:file', sprintf('file dosent exist: %s', fnTarget));
                    throw(ME)
                end
                imgFrames = load(fnTarget);
                testTargets(i).frames = imgFrames.frames;
            case 'ivs'
                fnTarget = fullfile(dataFullPath, [cell2str(testTargets(i).name), '.ivs']);
                p = Pipe.autopipe(fnTarget, 'viewResults', 0 ,'outputdir',  'C:\temp\pipeOutDir\');
                testTargets(i).frames = struct('z',p.zImg,'i',p.iImg,'c',p.cImg)
        end
    end
end