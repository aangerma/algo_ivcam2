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
%%
[ver,sub] = calibToolVersion();
outputFolder = sprintf('\\\\ger\\ec\\proj\\ha\\RSG\\SA_3DCam\\Algorithm\\Releases\\IVCAM2.0\\IV2AlgoCameraCalibTool%s\\%1.2f.%1.0f\\',gProjID,ver,sub);
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
    ],outputFolder,toolConfig.presetsDefFolder,toolConfig.configurationFolder);
eval(cmd);



copyfile(toolConfig.calibParamsFile,outputFolder);
copyfile(toolConfigFile,fullfile(outputFolder, 'IV2AlgoCameraCalibTool.xml'));
fw = Pipe.loadFirmware(sprintf('../../../+Calibration/%s',toolConfig.configurationFolder));
vregs.FRMW.calibVersion = uint32(hex2dec(single2hex(calibToolVersion)));
vregs.FRMW.configVersion = uint32(hex2dec(single2hex(calibToolVersion)));
fw.setRegs(vregs,'');
% Generate tables for old firmware
fw.writeFirmwareFiles(fullfile(outputFolder,'configFilesNoAlgoGen'));
fw.writeDynamicRangeTable(fullfile(outputFolder,'configFilesNoAlgoGen',sprintf('Dynamic_Range_Info_CalibInfo_Ver_00_%02.0f.bin',mod(calibToolVersion,1)*100)));
% Generate tables for firmware with Algo Gen
fw.generateTablesForFw(fullfile(outputFolder,'configFiles'));
fw.writeDynamicRangeTable(fullfile(outputFolder,'configFiles',sprintf('Dynamic_Range_Info_CalibInfo_Ver_05_%02.0f.bin',mod(calibToolVersion,1)*100)),fullfile(ivcam2root,'+Calibration','+presets',['+',toolConfig.presetsDefFolder]));

%% Generate default algo thermal table


% %%
% mcc -m IV2rgbCalibTool.m ...
%     -d  \\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\IV2AlgoCameraCalibTool\1.06\ ...
%     -a ..\..\+Pipe\tables\* ...
%     -a .\@ADB\*...
%     -a ..\..\+Calibration\initConfigCalib\*...
%     -a ..\..\@HWinterface\presetScripts\*...
%     -a ..\..\@HWinterface\IVCam20Device\*