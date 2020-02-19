
if isempty(strfind(version, 'R2018b')) %#ok
    error('build_IV2calibTool() must be ran with Matlab R2018b!');
end


outputFolder = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\registerUpdateGUI';
mkdirSafe(outputFolder);
cmd = sprintf([
    'mcc -m registerUpdateGUI.m ' ...
    '-d  %s '...
    '-a ..\\..\\+Pipe\\tables\\* '...
    '-a ..\\..\\+Calibration\\initConfigCalib\\* '...
    '-a ..\\..\\@HWinterface\\presetScripts\\* '...
    '-a ..\\..\\@HWinterface\\IVCam20Device\\* '...
    ],outputFolder);
eval(cmd);



copyfile('registerUpdateGUI.xml',outputFolder);