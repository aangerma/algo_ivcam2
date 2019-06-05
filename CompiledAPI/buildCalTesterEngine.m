function res = buildCalTesterEngine(isCopyToPrebuild)

    if ~exist('isCopyToPrebuild','var')
        isCopyToPrebuild = 1;
    end
    source = fullfile(ivcam2root,'scripts','IV2calibTool','calibParams.xml');
    target = fullfile(ivcam2root,'CompiledAPI','calibParams.xml');
    copyfile(source,target,'f');
    
    Files = { 'cal_init.m' ...
            ,'IR_DelayCalibCalc' ...
            ,'Z_DelayCalibCalc' ... 
            ,'DSM_CoarseCalib_Calc.m' ...
            ,'Version.m' ...
            ,'DSM_Calib_Calc.m' ...
            ,'DFZ_Calib_Calc.m' ...
            ,'ROI_Calib_Calc.m' ...
            ,'END_calib_Calc.m' ...
            ,'RGB_Calib_Calc.m' ...
            ,'TemDataFrame_Calc.m' ...      % algo2
            ,'HVM_Val_Calc.m' ...           % val (dfz ,sharpness ,temporalNoise ,roi ,los)
            ,'HVM_Val_Coverage_Calc.m' ...  % val (coverage)
            ,'Preset_Calib_Calc.m' ...
            };
    
    Attachments = {'calibParams.xml'};
    
    % .NET app, IVCAM2.Algo.CalibrationMatlab library,
    % CalibrationEngine class, .NET version 4.5, no encryption, local app
    Target = 'dotnet:IVCAM2.Algo.CalibrationMatlab,CalibrationEngine,4.0,Private,local';
    OutDir = 'Output';
    prebuildDir = '\prebuilt\CalibrationEngine';
    
    chunks = strsplit(pwd, filesep);
    
    if (~strcmp(chunks{end}, 'CompiledAPI'))
        error('buildCalibrationEngine() must be ran from CompiledAPI directory!');
    end
    
    if exist(OutDir, 'dir')
        rmdir(OutDir, 's');
    end
    
    if isempty(strfind(version, 'R2018a')) %#ok
        error('buildCalibrationEngine() must be ran with Matlab R2018a!');
    end
    
    args = { '-W', Target, '-d', OutDir, '-T', 'link:lib', '-v', Files{:}, '-a', Attachments{:} }; %#ok
    fprintf('Running mcc with %s\n\n', strjoin(args, ' '));
    
    mkdir(OutDir);
    mcc(args{:});
    fprintf('\n');
    
    fprintf('Generating final library ...\n')
    system(['ILMerge.exe ' OutDir '\CalibrationMatlab.dll /attr:attributes\IVCAM2.Algo.CalibrationMatlab.dll /out:' OutDir '\IVCAM2.Algo.CalibrationMatlab.dll']);
    
    try
        outDll = fullfile(OutDir,'IVCAM2.Algo.CalibrationMatlab.dll');
        if exist(outDll,'file')
            if isCopyToPrebuild
                targetFile = fullfile(prebuildDir,'IVCAM2.Algo.CalibrationMatlab.dll');
                res = copyfile(outDll,targetFile,'f');
            else
                res = 1;
            end
        else
            res = 0;
        end
    catch ex
        disp(ex);
        res = 0;
    end
    
end
