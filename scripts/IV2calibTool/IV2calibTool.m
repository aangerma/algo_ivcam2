classdef IV2calibTool < matlab.apps.AppBase
%     mcc -m POC4rangeFinder.m -d \\ger\ec\proj\ha\perc\SA_3DCam\Ohad\share\POC4RangeFinder\ -a ..\..\+Pipe\tables\* -a .\*

% \\invcam450\D\data\ivcam20\exp\20180204_MA

    % Properties that correspond to app components
    properties (Access = public)
        IV2calibrationtoolUIFigure      matlab.ui.Figure
        StartButton                     matlab.ui.control.Button
        OutputdirectortyEditFieldLabel  matlab.ui.control.Label
        Outputdirectorty                matlab.ui.control.EditField
        ConfigdirectortyLabel           matlab.ui.control.Label
        Configdirectorty                matlab.ui.control.EditField
        Button_2                        matlab.ui.control.Button
        Button_3                        matlab.ui.control.Button
        logarea                         matlab.ui.control.TextArea
        verboseCheckBox                 matlab.ui.control.CheckBox
    end
    
    
    properties (Access = private)
        m_logfid % logfile handle
    end
    
    methods (Access = private)
        
        
        function saveDefaults(app)
            fields2save={'Configdirectorty','Outputdirectorty'};
            sinit=[fields2save;cellfun(@(x) app.(x).Value,fields2save,'uni',0)];
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
            for fld=ff(:)'
                if(~isempty(s.(fld{1})))
                    app.(fld{1}).Value=s.(fld{1});
                end
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
        
        
        function fprintff(app,varargin)
            fprintf(app.m_logfid,varargin{1:end-1});
            app.logarea.Value{1}=[ app.logarea.Value{1} sprintf(varargin{1:end-1})];
            if(varargin{end})
                app.logarea.Value=[{''};app.logarea.Value];
                fprintf(app.m_logfid,'\n');
            else
                
            end
            
        end
        
        function  showTargetRequestFig(app, hw, imgfn, figTitle)
            
            f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
            maximizeFig(f);
            a(1)=subplot(121,'parent',f);
            imagesc(imread(['./res/' imgfn '.png']),'parent',a(1));
            axis(a(1),'image');
            axis(a(1),'off');
            colormap(gray(256));
            title('Please insert calib target','parent',a(1));
            a(2)=subplot(122);
            % hw=HWinterface();
            while(ishandle(f) && get(f,'userdata')==0)
               
                raw=hw.getFrame();
                imagesc(raw.i);
                axis(a(2),'image');
                axis(a(2),'off');
                title(figTitle);
                colormap(gray(256));
                drawnow;
            end
            close(f);
            
        end
        
    end
    methods (Static=true,Access = private)
        function fn=defaultsFilename()
            fn='iv2defaults.xml';
        end
        
        
        
    end
    
    
    methods (Access = private)
        
        % Code that executes after component creation
        function startupFcn(app)
            app.loadDefaults();
            
            
        end
        
        % Button pushed function: Button_2
        function Button_2Pushed(app, event)
            app.setFolder(app.Configdirectorty);
            
        end
        
        % Button pushed function: Button_3
        function Button_3Pushed(app, event)
            app.setFolder(app.Outputdirectorty);
            
        end
        
        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            app.saveDefaults();

            app.m_logfid = fopen(fullfile(app.Outputdirectorty.Value,filesep,'log.log'),'w');
            fprintffS=@(varargin) app.fprintff(varargin{:});

            %fprintffS('Loading Firmware...',false);
            %fw=Pipe.loadFirmware(configFldr);
            %fprintffS('Done',true);
            %fprintffS('Connecting HW interface...',false);
            %hw=HWinterface(fw);
            hw=HWinterface();
            fprintffS('Done',true);
                        
            mkdirSafe(app.Outputdirectorty.Value);
            
            try
                app.showTargetRequestFig(hw, 'calibTarget','Adjust target such that the target edges appear within the image');
                Calibration.runCalibStream(hw, app.Configdirectorty.Value,app.Outputdirectorty.Value,fprintffS,app.verboseCheckBox.Value);
                %app.showTargetRequestFig(hw, 'undistCalib','Adjust target such that the target edges do not appear within the image');
                %TODO: add undist to the enire image
            catch e
                fprintffS('',true);
                fprintffS(sprintf('[!] ERROR:%s',e.message),true);
                errordlg(e.message);
            end
            fclose(app.m_logfid);
            clear hw;
        end
    end
    
    % App initialization and construction
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create IV2calibrationtoolUIFigure
            app.IV2calibrationtoolUIFigure = uifigure;
            app.IV2calibrationtoolUIFigure.Position = [100 100 640 480];
            centerfig(app.IV2calibrationtoolUIFigure);
            app.IV2calibrationtoolUIFigure.Name = 'IV2 calibration tool';
            
            % Create StartButton
            app.StartButton = uibutton(app.IV2calibrationtoolUIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.FontWeight = 'bold';
            app.StartButton.Position = [1 309 640 52];
            app.StartButton.Text = 'Start';
            
            % Create OutputdirectortyEditFieldLabel
            app.OutputdirectortyEditFieldLabel = uilabel(app.IV2calibrationtoolUIFigure);
            app.OutputdirectortyEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputdirectortyEditFieldLabel.Position = [1 402 94 15];
            app.OutputdirectortyEditFieldLabel.Text = 'Output directorty';
            
            % Create Outputdirectorty
            app.Outputdirectorty = uieditfield(app.IV2calibrationtoolUIFigure, 'text');
            app.Outputdirectorty.Position = [110 398 486 22];
            
            % Create ConfigdirectortyLabel
            app.ConfigdirectortyLabel = uilabel(app.IV2calibrationtoolUIFigure);
            app.ConfigdirectortyLabel.HorizontalAlignment = 'right';
            app.ConfigdirectortyLabel.Position = [1 432 94 15];
            app.ConfigdirectortyLabel.Text = 'Config directorty';
            
            % Create Configdirectorty
            app.Configdirectorty = uieditfield(app.IV2calibrationtoolUIFigure, 'text');
            app.Configdirectorty.Position = [110 428 486 22];
            
            % Create Button_2
            app.Button_2 = uibutton(app.IV2calibrationtoolUIFigure, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @Button_2Pushed, true);
            app.Button_2.Position = [606 428 21 22];
            app.Button_2.Text = '...';
            
            % Create Button_3
            app.Button_3 = uibutton(app.IV2calibrationtoolUIFigure, 'push');
            app.Button_3.ButtonPushedFcn = createCallbackFcn(app, @Button_3Pushed, true);
            app.Button_3.Position = [606 398 21 22];
            app.Button_3.Text = '...';
            
            % Create logarea
            app.logarea = uitextarea(app.IV2calibrationtoolUIFigure);
            app.logarea.Editable = 'off';
            app.logarea.Position = [1 1 640 289];
            
              % Create verboseCheckBox
            app.verboseCheckBox = uicheckbox(app.IV2calibrationtoolUIFigure);
            app.verboseCheckBox.Text = 'verbose';
            app.verboseCheckBox.Position = [110 368 486 22];
            
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