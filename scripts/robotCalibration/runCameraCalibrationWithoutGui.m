function calibPassed = runCameraCalibrationWithoutGui()
clear
defaultLocalPath ='C:\temp\unitCalib\';
toolDir = fullfile(ivcam2root,'Tools\CalibTools\AlgoCameraCalibration');
runParamsFile = 'IV2AlgoCameraCalibTool.xml';
hw = HWinterface;       
[info,serialStr,~] = hw.getInfo();
runParams = xml2structWrapper(fullfile(toolDir,runParamsFile));
app.toolName = runParams.toolName;
app.configurationFolder = runParams.configurationFolder;
app.presetsDefFolder = runParams.presetsDefFolder;
app.calibParamsFile = runParams.calibParamsFile;
app.defaultsFilename = fullfile(toolDir,runParamsFile);

cbnames = {'replayMode','warmUp','init','gamma','scanDir','minRangePreset','maxRangePreset','DFZ','ROI','undist','rgb','burnCalibrationToDevice','burnConfigurationToDevice','debug','pre_calib_validation','post_calib_validation','uniformProjectionDFZ','saveRegState','FOVexInstalled'};
    
app.disableAdvancedOptions = runParams.disableAdvancedOptions;
app.calibRes=runParams.calibRes;
for i=1:length(cbnames)
    f=cbnames{i};
    app.cb.(f).Value = true;
    app.cb.(f).edit = true;
end

s=xml2structWrapper(app.defaultsFilename);
if ~(exist(s.outputdirectory,'dir'))
    s.outputdirectory = defaultLocalPath;
end

ff=fieldnames(s);
for fld_=ff(:)'

    if(isempty(s.(fld_{1})))
        return;
    end
    fld=replaceFirst(fld_{1},'_','.');
    try
        if (eval(sprintf('app.%s.edit',fld)))
            eval(sprintf('app.%s.Value=s.(fld_{1});',fld));
        end
    catch e,%#ok
    end
end

runparams=structfun(@(x) x.Value,app.cb,'uni',0);
[runparams.version,runparams.subVersion] = AlgoCameraCalibToolVersion(); 
runparams.outputFolder = [];
runparams.replayFile = [];

revisionList = dirFolders(fullfile(s.outputdirectory,serialStr),'ACC*');
revInt = cellfun(@(x) (str2double(x.rev)), regexp(revisionList,'ACC(?<rev>\d+)','names'));
currRev = sprintf('ACC%02d',round(max([0;revInt(:)])+1));
runparams.outputFolder = fullfile(s.outputdirectory,serialStr,currRev);
runparams.configurationFolder = app.configurationFolder;
runparams.calibParamsFile = app.calibParamsFile;
runparams.calibRes = app.calibRes; 
runparams.presetsDefFolder = app.presetsDefFolder; 
calibfn =  fullfile(toolDir,app.calibParamsFile);
calibParams = xml2structWrapper(calibfn);

mkdirSafe(runparams.outputFolder);
infoFn = fullfile(runparams.outputFolder,'unit_info.txt');
fid = fopen(infoFn,'wt');
fprintf(fid, info);
fclose(fid);

runparamsFn = fullfile(runparams.outputFolder,'sessionParams.xml');
logFn = fullfile(runparams.outputFolder,'log.log');
        
struct2xmlWrapper(runparams,runparamsFn);        
calibParams.sparkParams.resultsFolder = runparams.outputFolder;
calibPassed = Calibration.runAlgoCameraCalibration(runparamsFn,calibfn,@fprintf,[],[]);
hw.cmd('rst');
clear
end
function strOut = replaceFirst(str,exp,replace)
    strOut = str;
    idx = strfind(str,exp);
    if idx>0
        strOut = [str( 1:idx-1 ) replace str(idx+length(exp):end)];
    end
end
