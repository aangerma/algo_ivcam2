%{
Steps for resleasing a new calibration gui:
1. Version - update in thermalCalibToolVersion()
2. Run the section below.
3. Look for differences in outputFiles in respect to previous version and verify only things that was supposed to change actually did.
%}

global gProjID;
if isempty(gProjID)
    gProjID = iv2Proj.L515;
end

if  gProjID == iv2Proj.L520
    toolConfigFile = 'IV2AlgoThermalCalibToolL520.xml';
else
    toolConfigFile = 'IV2AlgoThermalCalibTool.xml';
end

if isempty(strfind(version, 'R2018b')) %#ok
    error('build_IV2AlgoThermalCalibTool() must be ran with Matlab R2018b!');
end
toolConfig = xml2structWrapper(toolConfigFile);

%%
[ver,sub] = AlgoThermalCalibToolVersion();
outputFolder = sprintf('\\\\ger\\ec\\proj\\ha\\RSG\\SA_3DCam\\Algorithm\\Releases\\IVCAM2.0\\ATC_%s\\%1.2f.%1.0f\\',gProjID,ver,sub);
mkdirSafe(outputFolder);
cmd = sprintf([
    'mcc -m IV2AlgoThermalCalibTool.m ' ...
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



copyfile('calibParams.xml',outputFolder);
copyfile('IV2AlgoThermalCalibTool.xml',outputFolder);

% %%
% mcc -m IV2rgbCalibTool.m ...
%     -d  \\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\IV2AlgoThermalCalibTool\1.06\ ...
%     -a ..\..\+Pipe\tables\* ...
%     -a .\@ADB\*...
%     -a ..\..\+Calibration\initConfigCalib\*...
%     -a ..\..\@HWinterface\presetScripts\*...
%     -a ..\..\@HWinterface\IVCam20Device\*