function IV2calibTool
    app=createComponents();
    loadDefaults(app);
    outputFolderChange_callback(app.figH);
end

function outputFolderChange_callback(varargin)
    app=guidata(varargin{1});
    
    hwRecFile = fullfile(app.Outputdirectorty.String,filesep,'sessionRecord.mat');
    if(exist(hwRecFile ,'file') && ~app.cb.overwriteExisting.Value)
        app.StartButton.BackgroundColor=[.5 .94 .94];
        
        app.logarea.String={''};
        fprintff(app,'-=RECORD MODE=-\n loading file%s\n',hwRecFile);
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
    f=uigetdir(textboxH.String);
    if(f==0)
        return;
    end
    
    textboxH.String=f;
    outputFolderChange_callback(textboxH);
    
end


function ll=fprintff(app,varargin)
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
    
    drawnow;
end

function app=createComponents()
    sz=[640 700];
    % Create figH
    app.figH = figure('units','pixels',...
        'menubar','none',...
        'name','Verify Password.',...
        'resize','off',...
        'numbertitle','off',...
        'name','IV2 Calibration Tool');
    
    app.figH.Position(3)=sz(1);
    app.figH.Position(4) = sz(2);
    app.defaultsFilename='IV2calibTool.xml';
    centerfig(app.figH );
    
    tg = uitabgroup('Parent',app.figH);
    configurationTab=uitab(tg,'Title','configuration');
    advancedTab=uitab(tg,'Title','Advanced');
    app.figH.Resize='off';
    
    app.m_logfid=[];
    
    % Create StartButton
    app.StartButton = uicontrol('style','pushbutton','parent',configurationTab);
    app.StartButton.Callback = @statrtButton_callback;
    app.StartButton.FontWeight = 'bold';
    %     app.StartButton.FontSize=12;
    app.StartButton.Position = [1 sz(2)-131 sz(1)-4 52];
    app.StartButton.String = 'Start';
    
    % Create OutputdirectortyEditFieldLabel
    app.OutputdirectortyEditFieldLabel = uicontrol('style','text','parent',configurationTab);
    app.OutputdirectortyEditFieldLabel.HorizontalAlignment = 'right';
    app.OutputdirectortyEditFieldLabel.Position = [1 sz(2)-54 94 15];
    app.OutputdirectortyEditFieldLabel.String = 'Output directorty';
    
    % Create Outputdirectorty
    app.Outputdirectorty =  uicontrol('style','edit','parent',configurationTab);
    app.Outputdirectorty.HorizontalAlignment='left';
    app.Outputdirectorty.Position = [110 sz(2)-60 486 22];
    app.Outputdirectorty.KeyReleaseFcn=@outputFolderChange_callback;
    
    % Create VersionLabel
    app.VersionLabel = uicontrol('style','text','parent',configurationTab);
    app.VersionLabel.HorizontalAlignment = 'left';
    app.VersionLabel.Position = [5 sz(2)-146 94 15];
    app.VersionLabel.String = sprintf('version: %5.2f',calibToolVersion());
    
    
    % Create outputFldrBrowseBtn
    app.outputFldrBrowseBtn =  uicontrol('style','pushbutton','parent',configurationTab);
    app.outputFldrBrowseBtn.Callback = {@setFolder,app.Outputdirectorty};
    app.outputFldrBrowseBtn.Position = [606 sz(2)-60 21 22];
    app.outputFldrBrowseBtn.String = '...';
    
    % Create logarea
    app.logarea =uicontrol('style','edit','parent',configurationTab);
    app.logarea.HorizontalAlignment='left';
    app.logarea.BackgroundColor=[1 1 1]*0.9;
    app.logarea.UserData=app.logarea.BackgroundColor;
    app.logarea.Max=10;
    app.logarea.String='';
    app.logarea.Position = [1 1 640 sz(2)-151];
    app.logarea.FontName='courier new';
    % Create verboseCheckBox
    
    %checkboxes
    cbnames = {'overwriteExisting','verbose','init','DSM','gamma','dataDelay','ROI','DFZ','validation','undist','burnCalibrationToDevice','burnConfigurationToDevice','debug'};
    
    cbSz=[200 30];
    ny = floor(sz(2)/cbSz(2))-1;
    for i=1:length(cbnames)
        f=cbnames{i};
        app.cb.(f) = uicontrol('style','checkbox','parent',advancedTab);
        app.cb.(f).String = f;
        app.cb.(f).Position = [cbSz(1)*floor((i-1)/ny)+cbSz(2) cbSz(2)*(ny-(mod(i-1,ny)+1)) cbSz];
        app.cb.(f).Value = true;
        app.cb.(f).Callback=@outputFolderChange_callback;
        
        
    end
    % Create outputFldrBrowseBtn
    app.advancedSaveBtn = uicontrol('style','pushbutton','parent',advancedTab);
    app.advancedSaveBtn.Callback = @saveDefaults;
    app.advancedSaveBtn.Position = [560 10 50 22];
    app.advancedSaveBtn.String = 'save';
    guidata(app.figH,app);
    
    
end

function saveDefaults(varargin)
    app=guidata(varargin{1});
    
    s=structfun(@(x) x.Value,app.cb,'uni',0);
    s.Outputdirectorty=app.Outputdirectorty.String;
    
    struct2xmlWrapper(s,app.defaultsFilename);
    
    
    
 
    
end

function statrtButton_callback(varargin)
    app=guidata(varargin{1});
    fprintffS=@(varargin) fprintff(app,varargin{:});
     try
         
         if(exist(app.Outputdirectorty.String,'dir') && app.cb.overwriteExisting.Value)
             rmdir(app.Outputdirectorty.String,'s');
         end
         mkdirSafe(app.Outputdirectorty.String);
         
         
        app.logarea.BackgroundColor=app.logarea.UserData;
        
        
        app.m_logfid = fopen(fullfile(app.Outputdirectorty.String,filesep,'log.log'),'wt');
        
        
        % clear log
        outputFolderChange_callback(app.figH);
        
        
        runparams=structfun(@(x) x.Value,app.cb,'uni',0);
        runparams.version=calibToolVersion();
        runparams.outputFolder=app.Outputdirectorty.String;
        runparamsFn = fullfile(runparams.outputFolder,filesep,'sessionParams.xml');
        struct2xmlWrapper(runparams,runparamsFn);
        
        
        s=Spark('Algo','AlgoCalibration');
        s.addTestProperty('CalibVersion',calibToolVersion)
        s.startDUTsession('UnitSerialGoesHere');
        
        %%
        s.addDTSproperty('TargetType','IRcalibrationChart');
        
        
        
        
        set_watches(app.figH,false);
        
        %=======================================================RUN CALIBRATION=======================================================
        calibfn =  fullfile(pwd,'calibParams.xml');
        
        [calibPassed,score] = Calibration.runCalibStream(runparamsFn,calibfn,fprintffS);
        s.AddMetrics('score', score,1,100,false);
        if calibPassed
            app.logarea.BackgroundColor = [0 0.8 0]; % Color green
        else
            app.logarea.BackgroundColor = [0.8 0 0]; % Color red
        end
       
     catch e
        fprintffS('[!] ERROR:%s\n',strtrim(e.message));
        errordlg(e.message);
        fid = fopen(sprintf('%s%cerror_%s.log',app.Outputdirectorty.String,filesep,datestr(now,'YYYY_mm_dd_HH_MM_SS')),'w');
        if(fid~=-1)
        fprintf(fid,strrep(getReport(e),'\','\\'));
        fclose(fid);
        end
        s.endDUTsession([], true);
    end
    s.endDUTsession();
    fclose(app.m_logfid);
    set_watches(app.figH,true);
end