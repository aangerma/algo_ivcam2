function IV2calibTool
    app=createComponents();
    loadDefaults(app);
    outputFolderChange_callback(app.figH);
end
function outputFolderChange_callback(varargin)
    app=guidata(varargin{1});
    
    hwRecFile = fullfile(app.outputdirectorty.String,filesep,'sessionRecord.mat');
    if app.cb.replayMode.Value
        app.StartButton.BackgroundColor=[.5 .94 .94];
        app.logarea.String={''};
        if exist(hwRecFile ,'file')
            fprintff(app,'-=REPLAY MODE=-\n loading file %s\n',hwRecFile);
        end
    else
        app.logarea.String={''};
        app.StartButton.BackgroundColor=[.94 .94 .94];
    end
end

function loadDefaults(app)
    
    if(~exist(app.defaultsFilename,'file'))
        return;
    end
    s=xml2structWrapper(app.defaultsFilename);
    if ~(exist(s.outputdirectorty,'dir'))
        s.outputdirectorty = 'C:\temp\unitCalib\';
    end
    
    ff=fieldnames(s);
    for fld_=ff(:)'
        
        if(isempty(s.(fld_{1})))
            return;
        end
        fld=strrep(fld_{1},'_','.');
        try
            if(strcmp(eval(sprintf('app.%s.Style',fld)),'edit'))
                eval(sprintf('app.%s.String=s.(fld_{1});',fld));
            else
                eval(sprintf('app.%s.Value=s.(fld_{1});',fld));
            end
        catch e,%#ok
        end
        
    end
    
end

function setFolder(varargin)
    textboxH = varargin{3};
    app = guidata(varargin{1});
    if app.cb.replayMode.Value
        [fname, pathStr] = uigetfile('*.mat', 'Replay Mode',textboxH.String);
        if ~isempty(fname)
            f = fullfile(pathStr,fname);
        end
    else
        f = uigetdir(textboxH.String);
    end
    
    if f~=0
        textboxH.String=f;
        outputFolderChange_callback(textboxH);
    end
    
    
    
end


function ll=fprintff(app,varargin)
    if(app.AbortButton.UserData==0)
        app.AbortButton.UserData=1;%next call will not enter here
        error('USER ABORT');
    end
    logAreaH=app.logarea;
    if(~isempty(app.m_logfid))
        ll=fprintf(app.m_logfid, varargin{:});
    else
        ll=0;
    end
    txtline = sprintf(varargin{:});
    logAreaH.String{end} = [logAreaH.String{end} txtline];
    %     if(~isempty(txtline) && txtline(end)==newline)
    %         logAreaH.String{end+1}='';
    %     end
    logAreaH.Enable = 'on';
    drawnow;
end

function app=createComponents()
    runParams = xml2structWrapper('IV2calibTool.xml');
    
    
    sz=[640 700];
    % Create figH
    app.figH = figure('units','pixels',...
        'menubar','none',...
        'resize','off',...
        'numbertitle','off',...
        'name',runParams.toolName);
    if isdeployed
        toolDir = pwd;
    else
        toolDir = fileparts(mfilename('fullpath'));
    end
    app.toolName = runParams.toolName;
    app.figH.Position(3) = sz(1);
    app.figH.Position(4) = sz(2);
    app.defaultsFilename= fullfile(toolDir,'IV2calibTool.xml');
    centerfig(app.figH );
    
    tg = uitabgroup('Parent',app.figH);
    configurationTab=uitab(tg,'Title','Main');
    advancedTab=uitab(tg,'Title','Advanced');
    app.figH.Resize='off';
    
    app.m_logfid=[];
    
    % Create StartButton
    app.StartButton = uicontrol('style','pushbutton','parent',configurationTab);
    app.StartButton.Callback = @statrtButton_callback;
    app.StartButton.FontWeight = 'bold';
    app.StartButton.Position = [1 sz(2)-139 sz(1)-4 52];
    app.StartButton.String = 'Start';
    
    
    % Create abort
    app.AbortButton = uicontrol('style','pushbutton','parent',configurationTab);
    app.AbortButton.Callback = @abortButton_callback;
    app.AbortButton.FontWeight = 'bold';
    app.AbortButton.Position = [1 sz(2)-139 sz(1)-4 52];
    app.AbortButton.String = 'Abort';
    app.AbortButton.Visible='off';
    
    
    % Create outputdirectortyEditFieldLabel
    app.outputdirectortyEditFieldLabel = uicontrol('style','text','parent',configurationTab);
    app.outputdirectortyEditFieldLabel.HorizontalAlignment = 'left';
    app.outputdirectortyEditFieldLabel.Position = [10 sz(2)-56 94 15];
    app.outputdirectortyEditFieldLabel.String = 'Output directorty';
    
    % Create outputdirectorty
    app.outputdirectorty =  uicontrol('style','edit','parent',configurationTab);
    app.outputdirectorty.HorizontalAlignment='left';
    app.outputdirectorty.Position = [110 sz(2)-60 490 22];
    app.outputdirectorty.KeyReleaseFcn=@outputFolderChange_callback;
   
    % Create Operator field label
    app.operatorEditFieldLabel = uicontrol('style','text','parent',configurationTab);
    app.operatorEditFieldLabel.HorizontalAlignment = 'left';
    app.operatorEditFieldLabel.Position = [10 sz(2)-80 94 15];
    app.operatorEditFieldLabel.String = 'Operator';
    
    % Create operator name string
    app.operatorName =  uicontrol('style','edit','parent',configurationTab);
    app.operatorName.HorizontalAlignment='left';
    app.operatorName.Position = [110 sz(2)-84 200 22];
    
    % Create work order field label
    app.workOrderEditFieldLabel = uicontrol('style','text','parent',configurationTab);
    app.workOrderEditFieldLabel.HorizontalAlignment = 'left';
    app.workOrderEditFieldLabel.Position = [330 sz(2)-80 94 15];
    app.workOrderEditFieldLabel.String = 'WorkOrder';
    
    % Create work order name string
    app.workOrder =  uicontrol('style','edit','parent',configurationTab);
    app.workOrder.HorizontalAlignment='left';
    app.workOrder.Position = [400 sz(2)-84 200 22];
    
    % Create VersionLabel
    app.VersionLabel = uicontrol('style','text','parent',configurationTab);
    app.VersionLabel.HorizontalAlignment = 'left';
    app.VersionLabel.Position = [5 sz(2)-154 94 15];
    [ver,sub] = calibToolVersion();
    app.VersionLabel.String = sprintf('version: %5.2f.%1.0f',ver,sub);
    
    
    % Create outputFldrBrowseBtn
    app.outputFldrBrowseBtn =  uicontrol('style','pushbutton','parent',configurationTab);
    app.outputFldrBrowseBtn.Callback = {@setFolder,app.outputdirectorty};
    app.outputFldrBrowseBtn.Position = [606 sz(2)-60 21 22];
    app.outputFldrBrowseBtn.String = '...';

    
    %{
    % Create outputFldrBrowseBtn
    app.outputFldrBrowseBtn =  uicontrol('style','pushbutton','parent',configurationTab);
    app.outputFldrBrowseBtn.Callback = @addPoxtFix_callback;
    app.outputFldrBrowseBtn.Position = [520 sz(2)-60 81 22];
    app.outputFldrBrowseBtn.String = 'add unit postfix';
    %}
    
    % Create logarea
    app.logarea =uicontrol('style','edit','parent',configurationTab);
    app.logarea.HorizontalAlignment='left';
    app.logarea.BackgroundColor=[1 1 1]*0.9;
    app.logarea.UserData=app.logarea.BackgroundColor;
    app.logarea.Max=10;
    app.logarea.String='';
    app.logarea.Position = [1 1 640 sz(2)-159];
    app.logarea.FontName='courier new';
    % Create verboseCheckBox
    
    % Create invisible skip button
    app.skipWarmUpButton = uicontrol('style','pushbutton','parent',configurationTab);
    app.skipWarmUpButton.Callback = @skip_button_callback;
    app.skipWarmUpButton.FontWeight = 'bold';
    app.skipWarmUpButton.Position = [sz(1)-85 10 60 30];
    app.skipWarmUpButton.String = 'Skip';
    app.skipWarmUpButton.Visible = 'off';
    Calibration.aux.globalSkip( 1,0 );
    %checkboxes
    cbnames = {'replayMode','verbose','warm_up','init','DSM','gamma','dataDelay','scanDir','validateLOS','DFZ','ROI','undist','burnCalibrationToDevice','burnConfigurationToDevice','debug','pre_calib_validation','post_calib_validation','uniformProjectionDFZ','saveRegState'};
    
    cbSz=[200 30];
    ny = floor(sz(2)/cbSz(2))-1;
    app.disableAdvancedOptions = runParams.disableAdvancedOptions;
    if runParams.disableAdvancedOptions checkBoxesMode = 'inactive'; else checkBoxesMode = 'on'; end
    for i=1:length(cbnames)
        f=cbnames{i};
        app.cb.(f) = uicontrol('style','checkbox','parent',advancedTab,'enable',checkBoxesMode);
        app.cb.(f).String = f;
        app.cb.(f).Position = [cbSz(1)*floor((i-1)/ny)+cbSz(2) cbSz(2)*(ny-(mod(i-1,ny)+1)) cbSz];
        app.cb.(f).Value = true;
        app.cb.(f).Callback=@outputFolderChange_callback;
    end
    % Create advancedSaveBtn
    app.advancedSaveBtn = uicontrol('style','pushbutton','parent',advancedTab);
    app.advancedSaveBtn.Callback = @saveDefaults;
    app.advancedSaveBtn.Position = [560 10 50 22];
    app.advancedSaveBtn.String = 'save';
    
    % Create clear cb button
    app.advancedClearBtn = uicontrol('style','pushbutton','parent',advancedTab);
    app.advancedClearBtn.Callback = @clearCB;
    app.advancedClearBtn.Position = [30 10 50 22];
    app.advancedClearBtn.String = 'clear';
%     set(handles.checkbox1,'Enable','off')  %disable checkbox1





    guidata(app.figH,app);
    
    
end


function addPoxtFix_callback(varargin)
    
    app=guidata(varargin{1});
    set_watches(app.figH,false);
    
    if(isempty(app.outputdirectorty.String) || app.outputdirectorty.String(end)~=filesep)
        app.outputdirectorty.String(end+1)=filesep;
    end
    try
        hw = HWinterface;
        s=hw.getSerial();
    catch
    end
    app.outputdirectorty.String=fullfile(app.outputdirectorty.String,s,filesep);
    set_watches(app.figH,true);
end

function clearCB(varargin)
    app=guidata(varargin{1});
    
    f = fieldnames(app.cb);
    for i = 1:numel(f)
        app.cb.(f{i}).Value = 0;
    end

end
function saveDefaults(varargin)
    app=guidata(varargin{1});
    
    s=structfun(@(x) x.Value,app.cb,'uni',0);
    s=cell2struct(struct2cell(s),strcat('cb_',fieldnames(s)));
    s.outputdirectorty=app.outputdirectorty.String;
    s.disableAdvancedOptions = app.disableAdvancedOptions;
    s.toolName = app.toolName;
    if(isempty(s.outputdirectorty))
        s.outputdirectorty=' ';%structxml bug
    end
    struct2xmlWrapper(s,app.defaultsFilename);
    
    
    
    
    
end

function abortButton_callback(varargin)
    app=guidata(varargin{1});
    app.AbortButton.UserData=0;
    app.AbortButton.Enable='off';
end
function skip_button_callback(varargin)
    app=guidata(varargin{1});
    app.skipWarmUpButton.Visible = 'off';
    app.skipWarmUpButton.Enable = 'off';
    Calibration.aux.globalSkip(1,1);
end
function statrtButton_callback(varargin)
    app=guidata(varargin{1});
    try
        
        runparams=structfun(@(x) x.Value,app.cb,'uni',0);
        [runparams.version,runparams.subVersion] = calibToolVersion(); 
        runparams.outputFolder = [];
        runparams.replayFile = [];

        %temporary until we have valid log file
        app.m_logfid = 1;
        fprintffS=@(varargin) fprintff(app,varargin{:});
        info = ''; % Until reading from unit
        serialStr = '00000000'; % Until reading from unit
        fwVersion = ''; % Until reading from unit
        origOutputFolder = app.outputdirectorty.String;
        if app.cb.replayMode.Value
            seesionFile = app.outputdirectorty.String;
            [~,~, extensionStr] = fileparts(seesionFile);
            if ~(exist(seesionFile,'file') && strcmp(extensionStr,'.mat'))
                msg = sprintf( 'the file %s does not existor is not a valid session recording\n',app.outputdirectorty.String);
                fprintffS('[!] ERROR: %s',msg);
                errordlg(msg);
                return;
            end
            runparams.outputFolder = tempname;
            runparams.replayFile = app.outputdirectorty.String;
        else
            
            try
                hw = HWinterface;
                [info,serialStr,~] = hw.getInfo();
                fwVersion = hw.getFWVersion;
                hw.cmd('U0_IDLE_ENABLE 0');
                hw.cmd('rst');
                clear hw;
            catch e
                fprintffS('[!] ERROR:%s\n',strtrim(e.message));
                errordlg(e.message);
                return;
            end
            revisionList = dirFolders(fullfile(app.outputdirectorty.String,serialStr),'PC*');
            revInt = cellfun(@(x) (str2double(x.rev)), regexp(revisionList,'PC(?<rev>\d+)','names'));
            currRev = sprintf('PC%02d',round(max([0;revInt(:)])+1));
            app.outputdirectorty.String = fullfile(app.outputdirectorty.String,serialStr,currRev);
            runparams.outputFolder=app.outputdirectorty.String;
            
        end
        mkdirSafe(runparams.outputFolder);
        infoFn = fullfile(runparams.outputFolder,'unit_info.txt');
        fid = fopen(infoFn,'wt');
        fprintf(fid, info);
        fclose(fid);
        runparamsFn = fullfile(runparams.outputFolder,'sessionParams.xml');
        logFn = fullfile(runparams.outputFolder,'log.log');
        outputFolderChange_callback(app.figH);
        
        struct2xmlWrapper(runparams,runparamsFn);
        app.logarea.BackgroundColor=app.logarea.UserData;
        app.m_logfid = fopen(logFn,'wt');
        fprintffS=@(varargin) fprintff(app,varargin{:});

        
        % clear log
        if isdeployed
            toolDir = pwd;
        else
            toolDir = fileparts(mfilename('fullpath'));
        end
        calibfn =  fullfile(toolDir,'calibParams.xml');
        calibParams = xml2structWrapper(calibfn);
        calibParams.sparkParams.resultsFolder = runparams.outputFolder;
        if app.cb.replayMode.Value==0
            s=Spark(app.operatorName.String,app.workOrder.String,calibParams.sparkParams,fprintffS);
            s.addTestProperty('CalibToolVersion',runparams.version)
            s.addTestProperty('CalibToolSubVersion',runparams.subVersion)
            s.startDUTsession(serialStr);
            s.addTestProperty('FWVersion',fwVersion);
            addGvd2Spark(s,info);
            
%             s.addDTSproperty('TargetType','IRcalibrationChart');
        else
            s = [];
        end
        set_watches(app.figH,false);
        app.AbortButton.Visible='on';
        app.AbortButton.Enable='on';
        app.AbortButton.UserData=1;
        %%
        %=======================================================RUN CALIBRATION=======================================================
        
        calibfn =  fullfile(toolDir,'calibParams.xml');
        [calibPassed] = Calibration.runCalibStream(runparamsFn,calibfn,fprintffS,s,app);
        validPassed = 1;
        if calibPassed~=0 && runparams.post_calib_validation && app.cb.replayMode.Value == 0
            waitfor(msgbox('Please disconnect and reconnect the unit for validation. Press ok when done.'));
            [validPassed] = Calibration.validation.validateCalibration(runparams,calibParams,fprintffS,s);
        end
        
        if calibPassed == 1 || calibPassed == -1
            if validPassed
                app.logarea.BackgroundColor = [0 0.8 0]; % Color green
            else
                app.logarea.BackgroundColor = [1 1 0]; % Color yellow 
            end
        elseif calibPassed == 0
            app.logarea.BackgroundColor = [0.8 0 0]; % Color red
        end
        
        
        
    catch e
        fprintffS('[!] ERROR:%s\n',strtrim(e.message));
        fid = fopen(sprintf('%s%cerror_%s.log',app.outputdirectorty.String,filesep,datestr(now,'YYYY_mm_dd_HH_MM_SS')),'w');
        if(fid~=-1)
            fprintf(fid,strrep(getReport(e),'\','\\'));
            fclose(fid);
        end
        if app.cb.replayMode.Value == 0
            s.endDUTsession([], true);
        end
    end
    
    %restore original folder
    app.outputdirectorty.String = origOutputFolder;

    app.AbortButton.Visible='off';
    app.AbortButton.Enable='off';
    if app.cb.replayMode.Value == 0
        s.endDUTsession();
    end
    fclose(app.m_logfid);
    set_watches(app.figH,true);
end
function addGvd2Spark(s,gvd)
    C = strsplit(gvd,newline);
    for i = 1:numel(C)
        line = strsplit(C{i},{':',' '});
        if numel(line) > 1
            s.addTestProperty(['gvd_' line{1}(1:end-1)],line{2});
        end
    end
    
end