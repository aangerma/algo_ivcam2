%%
mcc -m IV2calibTool.m ...
    -d  \\ger\ec\proj\ha\perc\SA_3DCam\Ohad\share\IV2calibTool\ ...
    -a ..\..\+Pipe\tables\* ...
    -a ..\..\+Calibration\targets\*...
    -a ..\..\+Calibration\initScript\*...
    -a ..\..\@HWinterface\presetScripts\*...
    -a ..\..\@HWinterface\IVCam20Device\*
%%
mcc -m IV2rgbCalibTool.m ...
    -d  \\ger\ec\proj\ha\perc\SA_3DCam\Ohad\share\IV2calibTool\ ...
    -a .\@ADB\*...
    -a ..\..\@HWinterface\presetScripts\*...
    -a ..\..\@HWinterface\IVCam20Device\*