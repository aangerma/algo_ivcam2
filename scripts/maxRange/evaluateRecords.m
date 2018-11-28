
varargin = struct('config',struct('outputFolder', 'c:\\temp\\valTest\out', 'dataFolder', 'X:\Data\IvCam2\maxRange\testRecords', 'dataSource', 'file'));
testConfig.maxRange = struct('name', 'debug', 'metrics', 'fillRate', 'target', 'wall_10Reflectivity', 'distance', '260cm');
[score, out] = Validation.runIQValidation(testConfig, varargin);
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
    %  dataSource: (string), defult: HW, options: HW/file/ivs/bin      robot
    %  fullTargetListPath: (string), reletive file path + targets.xml
    %  targetFilesPath: (string), reletive file path + targets
    %  example: varargin = {struct('config',struct('outputFolder', 'c:\\temp\\valTest', 'dataFolder', 'c:\\temp\\valTest\\data', 'dataSource', 'HW'))}

    %  Debug
%       varargin = {struct('config',struct('outputFolder', 'c:\\temp\\valTest\out', 'dataFolder', 'X:\Avv\sources\ivs\gen2\turn_in', 'dataSource', 'ivs'))}
%       testConfig.minRange = struct('name', 'debug', 'metrics', 'fillRate', 'target', 'wall_80Reflectivity', 'distance', '3m')
