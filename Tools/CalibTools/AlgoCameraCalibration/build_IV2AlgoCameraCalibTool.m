%{
Steps for resleasing a new calibration gui:
1. Version - update in calibToolVersion()
2. Run the section below.
3. Look for differences in outputFiles in respect to previous version and verify only things that was supposed to change actually did.
%}

global gProjID;
if isempty(gProjID)
    gProjID = iv2Proj.L515;
end

if  gProjID == iv2Proj.L520
    toolConfigFile = 'IV2AlgoCameraCalibToolL520.xml';
else
    toolConfigFile = 'IV2AlgoCameraCalibTool.xml';
end

if isempty(strfind(version, 'R2018b')) %#ok
    error('build_IV2AlgoCameraCalibTool() must be ran with Matlab R2018b!');
end
toolConfig = xml2structWrapper(toolConfigFile);
calibParams = xml2structWrapper(toolConfig.calibParamsFile);
%%
[vers,sub] = AlgoCameraCalibToolVersion;
outputFolder = sprintf('\\\\ger\\ec\\proj\\ha\\RSG\\SA_3DCam\\Algorithm\\Releases\\IVCAM2.0\\ACC_%s\\%1.2f.%1.0f\\',gProjID,vers,sub);
mkdirSafe(outputFolder);
cmd = sprintf([
    'mcc -m IV2AlgoCameraCalibTool.m ' ...
    '-d  %s '...
    '-a ..\\..\\..\\+Pipe\\tables\\* '...
    '-a ..\\..\\..\\+Calibration\\+presets\\+%s\\* '...
    '-a ..\\..\\..\\+Calibration\\targets\\* '...
    '-a ..\\..\\..\\+Calibration\\%s\\* '...
    '-a ..\\..\\..\\+Calibration\\eepromStructure\\* '...
    '-a ..\\..\\..\\@HWinterface\\presetScripts\\* '...
    '-a ..\\..\\..\\@HWinterface\\IVCam20Device\\* '...
    '-a ..\\@Spark\\* '...
    ],outputFolder, toolConfig.presetsDefFolder, toolConfig.configurationFolder);
eval(cmd);

copyfile(toolConfig.calibParamsFile,outputFolder);
copyfile(toolConfigFile,fullfile(outputFolder, 'IV2AlgoCameraCalibTool.xml'));
configurationFolder = sprintf('../../../+Calibration/%s',toolConfig.configurationFolder);
Calibration.aux.defineFileNamesAndCreateResultsDir(fullfile(outputFolder, 'AlgoInternal'), configurationFolder);
GenInitCalibTables_Calc_int(fullfile(outputFolder, 'AlgoInternal'), fullfile(outputFolder,'configFiles'), vers, calibParams.tableVersions);

% %%
% mcc -m IV2rgbCalibTool.m ...
%     -d  \\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\IV2AlgoCameraCalibTool\1.06\ ...
%     -a ..\..\+Pipe\tables\* ...
%     -a .\@ADB\*...
%     -a ..\..\+Calibration\initConfigCalib\*...
%     -a ..\..\@HWinterface\presetScripts\*...
%     -a ..\..\@HWinterface\IVCam20Device\*