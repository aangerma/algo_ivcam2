classdef IV2calibTool < matlab.apps.AppBase

%  


    % Properties that correspond to app components
    properties (Access = public)
        IV2calibrationtoolUIFigure      matlab.ui.Figure
        StartButton                     matlab.ui.control.Button
        OutputdirectortyEditFieldLabel  matlab.ui.control.Label
        Outputdirectorty                matlab.ui.control.EditField
        
        
        Button_2                        matlab.ui.control.Button 
        Button_3                        matlab.ui.control.Button
        Button_4                        matlab.ui.control.Button
        logarea                         matlab.ui.control.TextArea
        verboseCheckBox                 matlab.ui.control.CheckBox
        doInitCheckBox                  matlab.ui.control.CheckBox
        cb
        VersionLabel                    matlab.ui.control.Label
    end
    
       methods (Static=true,Access = private)
        function fn=defaultsFilename()
            fn='iv2defaults.xml';
        end
        
         
        function v=getFieldRec(app,x)
            ii=find(x=='.',1);
            if(isempty(ii))
                v=app.(x).Value;
            else
                v=IV2calibTool.getFieldRec(app.(x(1:ii-1)),x(ii+1:end));
            end
        end
        
    end
    
    
    properties (Access = private)
        m_logfid % logfile handle
    end
    
    methods (Access = private)
       
        
        function saveDefaults(app,~)
            fields2save=['Outputdirectorty',strcat('cb.',fieldnames(app.cb))'];
            sinit=[strrep(fields2save,'.','_');cellfun(@(x) IV2calibTool.getFieldRec(app,x),fields2save,'uni',0)];
            sinit(2,:)=cellfun(@(x) iff(isempty(x),[],x),sinit(2,:),'uni',0);
            s=struct(sinit{:});
            struct2xmlWrapper(s,app.defaultsFilename());
            
        end
        function loadDefaults(app)
            if(~exist(app.defaultsFilename(),'file'))
                return;
            end
            s=xml2structWrapper(app.defaultsFilename());
            ff=fieldnames(s);
            for fld_=ff(:)'
                fld=fld_{1};
                if(isempty(s.(fld)))
                    return;
                end
                eval(sprintf('app.%s.Value=s.(fld);',strrep(fld,'_','.')));
                
            end
            
        end
        function setFolder(app,textboxH)
            f=uigetdir(textboxH.Value);
            app.IV2calibrationtoolUIFigure.Visible = 'off';
            app.IV2calibrationtoolUIFigure.Visible = 'on';
            
            if(isempty(f))
                return;
            else
                textboxH.Value=f;
            end
        end
        
        
        function ll=fprintff(app,varargin)
            ll=fprintf(app.m_logfid, varargin{:});
            txtline = sprintf(varargin{:});
            app.logarea.Value{end} = [app.logarea.Value{end} txtline];
            if(~isempty(txtline) && txtline(end)==newline)
                app.logarea.Value{end+1}='';
            end
%             fprintf(app.m_logfid,varargin{1:end-1});
%             app.logarea.Value{1}=[ app.logarea.Value{1} sprintf(varargin{1:end-1})];
%             if(varargin{end})
%                 app.logarea.Value=[{''};app.logarea.Value];
%                 fprintf(app.m_logfid,'\n');
%             end
            
        end
    
        
    end
 
    
    methods (Access = private)
        
        % Code that executes after component creation
        function startupFcn(app)
            app.loadDefaults();
            
            
        end
        
        % Button pushed function: Button_2
        
        % Button pushed function: Button_3
        function Button_3Pushed(app, ~)
            app.setFolder(app.Outputdirectorty);
            
        end
        
        % Button pushed function: StartButton
        function StartButtonPushed(app, ~)
           
            app.logarea.BackgroundColor = [1,1,1];% reset textbox color
            mkdirSafe(app.Outputdirectorty.Value);
            
            app.m_logfid = fopen(fullfile(app.Outputdirectorty.Value,filesep,'log.log'),'wt');
            fprintffS=@(varargin) app.fprintff(varargin{:});

            % clear log
            app.logarea.Value = {''};
            
            
            params=structfun(@(x) x.Value,app.cb,'uni',0);
            params.outputFolder=app.Outputdirectorty.Value;
            params.version=calibToolVersion();
            
            s=Spark('Algo','AlgoCalibration');
            s.addTestProperty('CalibVersion',calibToolVersion)
            s.startDUTsession('UnitSerialGoesHere');
            
            %%
             s.addDTSproperty('TargetType','IRcalibrationChart');

           
            
         
            
            try
                %=======================================================RUN CALIBRATION=======================================================
                calibfn =  fullfile(pwd,'calibParams.xml');
                if exist(calibfn, 'file') == 2
                    calibParams = xml2structWrapper(calibfn);
                    s.setOutputFolder(calibParams.sparkOutputFolder);
                else
                    calibParams = [];
                end
                
                [calibPassed,score] = Calibration.runCalibStream(params,calibParams,fprintffS);
                s.AddMetrics('score', score,1,100,false);
                if calibPassed
                   app.logarea.BackgroundColor = [0 0.8 0]; % Color green 
                else
                   app.logarea.BackgroundColor = [0.8 0 0]; % Color red 
                end
               
            catch e
                fprintffS('');
                fprintffS('[!] ERROR:%s\n',e.message);
                errordlg(e.message);
                fid = fopen(sprintf('%s%cerror_%s.log',app.Outputdirectorty.Value,filesep,datestr(now,'YYYY_mm_dd_HH_MM_SS')),'w');
                fprintf(fid,strrep(getReport(e),'\','\\'));
                fclose(fid);
                s.endDUTsession([], true);
            end
            s.endDUTsession();
            fclose(app.m_logfid);
        end
    end
    
    % App initialization and construction
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create IV2calibrationtoolUIFigure
            app.IV2calibrationtoolUIFigure = uifigure();
            app.IV2calibrationtoolUIFigure.Position(4) = 700;
            sz=[640 700];
            tg = uitabgroup('Parent',app.IV2calibrationtoolUIFigure,'position',[0 0 sz]);
            configurationTab=uitab(tg,'Title','configuration');
            advancedTab=uitab(tg,'Title','Advanced');
            app.IV2calibrationtoolUIFigure.Resize='off';
            app.IV2calibrationtoolUIFigure.Position = [100 100 sz];
            centerfig(app.IV2calibrationtoolUIFigure);
            app.IV2calibrationtoolUIFigure.Name = 'IV2 calibration tool';
            


            % Create StartButton
            app.StartButton = uibutton(configurationTab, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.FontWeight = 'bold';
            app.StartButton.Position = [1 sz(2)-131 640 52];
            app.StartButton.Text = 'Start';
            
            % Create OutputdirectortyEditFieldLabel
            app.OutputdirectortyEditFieldLabel = uilabel(configurationTab);
            app.OutputdirectortyEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputdirectortyEditFieldLabel.Position = [1 sz(2)-54 94 15];
            app.OutputdirectortyEditFieldLabel.Text = 'Output directorty';
            
            % Create Outputdirectorty
            app.Outputdirectorty = uieditfield(configurationTab, 'text');
            app.Outputdirectorty.Position = [110 sz(2)-60 486 22];
            
            % Create VersionLabel
            app.VersionLabel = uilabel(configurationTab);
            app.VersionLabel.HorizontalAlignment = 'left';
            app.VersionLabel.Position = [5 sz(2)-146 94 15];
            app.VersionLabel.Text = sprintf('version: %5.2f',calibToolVersion());
            
            
            % Create Button_3
            app.Button_3 = uibutton(configurationTab, 'push');
            app.Button_3.ButtonPushedFcn = createCallbackFcn(app, @Button_3Pushed, true);
            app.Button_3.Position = [606 sz(2)-60 21 22];
            app.Button_3.Text = '...';
            
            % Create logarea
            app.logarea = uitextarea(configurationTab);
            app.logarea.Editable = 'off';
            app.logarea.Position = [1 1 640 sz(2)-151];
            app.logarea.FontName='courier new';
              % Create verboseCheckBox
             
              %checkboxes
              cbnames = {'verbose','init','DSM','gamma','dataDelay','ROI','DFZ','validation','undist','burnCalibrationToDevice','burnConfigurationToDevice','debug'};
              cbSz=[200 30];
              ny = floor(sz(2)/cbSz(2))-1;
              for i=1:length(cbnames)
                  f=cbnames{i};
                    app.cb.(f) = uicheckbox(advancedTab);
                    app.cb.(f).Text = f;
                    app.cb.(f).Position = [cbSz(1)*floor((i-1)/ny)+cbSz(2) cbSz(2)*(ny-(mod(i-1,ny)+1)) cbSz];
                    app.cb.(f).Value = true;

                  
              end
             % Create Button_3
            app.Button_4 = uibutton(advancedTab, 'push');
            app.Button_4.ButtonPushedFcn = createCallbackFcn(app, @saveDefaults, true);
            app.Button_4.Position = [560 10 50 22];
            app.Button_4.Text = 'save';
            
            
            
        end
    end
    
    methods (Access = public)
        
        % Construct app
        function app = IV2calibTool
            
            % Create and configure components
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.IV2calibrationtoolUIFigure)
            
            % Execute the startup function
            runStartupFcn(app, @startupFcn)
            
            if nargout == 0
                clear app
            end
        end
        
        % Code that executes before app deletion
        function delete(app)
            
            % Delete UIFigure when app is deleted
            delete(app.IV2calibrationtoolUIFigure)
        end
    end
end