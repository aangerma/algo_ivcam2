%{
Steps for resleasing a new calibration gui:
1. Version - update in thermalCalibToolVersion()
2. Run the section below.
3. Look for differences in outputFiles in respect to previous version and verify only things that was supposed to change actually did.
%}

if isempty(strfind(version, 'R2018b')) %#ok
    error('build_IV2calibTool() must be run with Matlab R2018b!');
end

%%
[ver,sub] = thermalCalibToolVersion();
outputFolder = sprintf('\\\\ger\\ec\\proj\\ha\\RSG\\SA_3DCam\\Algorithm\\Releases\\IVCAM2.0\\IV2thermalCalibTool\\%1.2f.%1.0f\\',ver,sub);
mkdirSafe(outputFolder);
cmd = sprintf([
    'mcc -m IV2ThermalCalibTool.m ' ...
    '-d  %s '...
    '-a ..\\..\\..\\+Pipe\\tables\\* '...
    '-a ..\\..\\..\\@HWinterface\\presetScripts\\* '...
    '-a ..\\..\\..\\+Calibration\\releaseConfigCalibVGA\\* '...
    '-a ..\\..\\..\\+Calibration\\releaseConfigCalibVXGA\\* '...
    '-a ..\\..\\..\\+Calibration\\releaseConfigCalibXGA\\* '...
    '-a ..\\..\\..\\+Calibration\\releaseConfigCalibL520\\* '...
    '-a ..\\..\\..\\+Calibration\\eepromStructure\\* '...
    '-a ..\\..\\..\\+Calibration\\+thermal\\+confidenceScipt\\* '...
    '-a ..\\..\\..\\@HWinterface\\IVCam20Device\\* '...
    '-a ..\\@Spark\\* '...
    ],outputFolder);
eval(cmd);



copyfile('calibParams.xml',outputFolder);
copyfile('IV2ThermalCalibTool.xml',outputFolder);

% %%
% mcc -m IV2rgbCalibTool.m ...
%     -d  \\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\IV2calibTool\1.06\ ...
%     -a ..\..\+Pipe\tables\* ...
%     -a .\@ADB\*...
%     -a ..\..\+Calibration\initConfigCalib\*...
%     -a ..\..\@HWinterface\presetScripts\*...
%     -a ..\..\@HWinterface\IVCam20Device\*