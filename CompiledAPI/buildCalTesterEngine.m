function res = buildCalTesterEngine(isCopyToPrebuild)

    % sanity check
    if isempty(strfind(version, 'R2018b')) %#ok
        error('buildCalibrationEngine() must be ran with Matlab R2018b!');
    end
    chunks = strsplit(pwd, filesep);
    if (~strcmp(chunks{end}, 'CompiledAPI'))
        error('buildCalibrationEngine() must be ran from CompiledAPI directory!');
    end
    
    % API's list
    Files = {'Version.m' ...
            ,'cal_init.m' ...
            ,'GenInitCalibTables_Calc.m' ...
            ,'DSM_CoarseCalib_Calc.m' ...
            ,'IR_DelayCalibCalc.m' ...
            ,'Z_DelayCalibCalc.m' ...
            ,'TmptrDataFrame_Calc.m' ...
            ,'SyncLoopCalib_Calc.m' ...
            ,'DSM_Calib_Calc.m' ...
            ,'Preset_Short_Calib_Calc.m' ...
            ,'DFZ_Calib_Calc.m' ...
            ,'RtdOverAngX_Calib_Calc.m' ...
            ,'ROI_Calib_Calc.m' ...
            ,'END_calib_Calc.m' ...
            ,'RtdOverAngXStateValues_Calib_Calc' ...
            ,'RtdOverAngX_Calib_Calc' ...
            ,'Preset_Long_Calib_Calc.m' ...
            ,'GeneratePresetsTable_Calib_Calc' ...
            ,'PresetsAlignment_Calib_Calc' ...
            ,'UpdateShortPresetRtdDiff_Calib_Calc' ...
            ,'RGB_Calib_Calc.m' ...
            ,'HVM_Val_Calc.m' ...
            ,'HVM_Val_Coverage_Calc.m' ...
            };

    % out folder preparation
    OutDir = 'Output';
    if exist(OutDir, 'dir')
        rmdir(OutDir, 's');
    end
    mkdir(OutDir);

    % copying meta data
    source = fullfile(ivcam2root,'Tools','CalibTools','AlgoThermalCalibration','calibParams.xml');
    target = fullfile(OutDir,'CalibParams','calibParams.xml');
    copyfile(source,target,'f');
    
    source = fullfile(ivcam2root,'Tools','CalibTools','AlgoCameraCalibration','calibParamsVXGA.xml');
    target = fullfile(OutDir,'CalibParams','calibParamsVXGA.xml');
    copyfile(source,target,'f');

    internalFolder = fullfile(OutDir,'CalibFiles');
    configurationFolder = fullfile(ivcam2root,'+Calibration','releaseConfigCalibVXGA');
    Calibration.aux.defineFileNamesAndCreateResultsDir(internalFolder, configurationFolder)

    calibParams = xml2structWrapper(source);
    GenInitCalibTables_Calc_int(internalFolder, fullfile(OutDir,'DefaultTables'), 0, calibParams.tableVersions);
    
    % Compilation
        % .NET app, IVCAM2.Algo.CalibrationMatlab library,
        % CalibrationEngine class, .NET version 4.5, no encryption, local app
    Target = 'dotnet:IVCAM2.Algo.CalibrationMatlab,CalibrationEngine,4.0,Private,local';
    args = { '-W', Target, '-d', OutDir, '-T', 'link:lib', '-v', Files{:} }; %#ok
    % tbToUse = {'curvefit', 'images', 'signal', 'stats', 'vision'}; % required toolboxes
    % pToInclude = cellfun(@(x)(fullfile(matlabroot,'toolbox',x)),tbToUse,'uni',false);
    % pToInclude = [repmat({'-p'},1,length(pToInclude)) ; pToInclude];
    % args = { '-N', pToInclude{:}, '-W', Target, '-d', OutDir, '-T', 'link:lib', '-v', Files{:}, '-a', Attachments{:} }; %#ok
    fprintf('Running mcc with %s\n\n', strjoin(args, ' '));
    
    mcc(args{:});
    fprintf('\n');
    
    fprintf('Generating final library ...\n')
    system(['ILMerge.exe ' OutDir '\CalibrationMatlab.dll /attr:attributes\IVCAM2.Algo.CalibrationMatlab.dll /out:' OutDir '\IVCAM2.Algo.CalibrationMatlab.dll']);

    % pre build
    if ~exist('isCopyToPrebuild','var')
        isCopyToPrebuild = 1;
    end
    prebuildDir = '\prebuilt\CalibrationEngine';
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
