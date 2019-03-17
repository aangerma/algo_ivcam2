%{
Steps for resleasing a new calibration gui:
1. Version - update in calibToolVersion()
2. Run the section below.
3. Look for differences in outputFiles in respect to previous version and verify only things that was supposed to change actually did.
%}

if isempty(strfind(version, 'R2017a')) %#ok
    error('build_IV2calibTool() must be ran with Matlab R2017a!');
end

%%
outputFolder = sprintf('\\\\ger\\ec\\proj\\ha\\RSG\\SA_3DCam\\Algorithm\\Releases\\IVCAM2.0\\IV2calibTool\\%1.2f\\',calibToolVersion());
mkdirSafe(outputFolder);
cmd = sprintf([
    'mcc -m IV2calibTool.m ' ...
    '-d  %s '...
    '-a ..\\..\\+Pipe\\tables\\* '...
    '-a ..\\..\\+Calibration\\targets\\* '...
    '-a ..\\..\\+Calibration\\releaseConfigCalib\\* '...
    '-a ..\\..\\@HWinterface\\presetScripts\\* '...
    '-a ..\\..\\@HWinterface\\IVCam20Device\\* '...
    '-a .\\@Spark\\* '...
    ],outputFolder);
eval(cmd);



copyfile('calibParams.xml',outputFolder);
copyfile('IV2calibTool.xml',outputFolder);
fw = Pipe.loadFirmware('../../+Calibration/releaseConfigCalib');

verReg = typecast(uint8([ mod(calibToolVersion,1)*100 floor(calibToolVersion) 0 0]),'uint32');
vreg= [verReg 0 0 0 0 verReg 0 0 ];
fw.setRegs('DIGGspare',vreg);
fw.writeFirmwareFiles(fullfile(outputFolder,'configFiles'),false);


%% Generate default algo thermal table


% %%
% mcc -m IV2rgbCalibTool.m ...
%     -d  \\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\IV2calibTool\1.06\ ...
%     -a ..\..\+Pipe\tables\* ...
%     -a .\@ADB\*...
%     -a ..\..\+Calibration\initConfigCalib\*...
%     -a ..\..\@HWinterface\presetScripts\*...
%     -a ..\..\@HWinterface\IVCam20Device\*