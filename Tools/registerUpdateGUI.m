% mcc -m registerUpdateGUI.m -d \\ger\ec\proj\ha\RSG\SA_3DCam\ohad\ -a ..\+Pipe\tables\* -a ..\@HWinterface\IVCam20Device\* -a ..\@HWinterface\\presetScripts\*
function registerUpdateGUI
    createComponents();
    
end

function editFIeldUpdate(app,trgt)
    ri=trgt.UserData;
    if(app.data(ri).updated)
        bgcolor = [.24 .94 .24];
    else
        bgcolor = [.94 .94 .94];
    end
    
    v=uint32(app.data(ri).value);
    if(~isempty(v))
        switch(app.data(ri).type)
            case 'logical'
                if app.data((ri)).arraySize > 1
                    trgt.String=dec2hex(v);
                    trgt.TooltipString=num2str(v);
                    set(trgt,'BackgroundColor',bgcolor);
                else
                    cc=get(trgt,'children');
                    set(cc,'BackgroundColor',bgcolor);
                    cc(1+v).Value=1;
                end
            case 'single'
                trgt.String=sprintf('%f',typecast(v,'single'));
                trgt.TooltipString=['0x' dec2hex(v)];
                set(trgt,'BackgroundColor',bgcolor);
            otherwise
                trgt.String=dec2hex(v);
                trgt.TooltipString=num2str(v);
                set(trgt,'BackgroundColor',bgcolor);
                
        end
    end
end

function valueWrite_callback(trgt)
    app=guidata(trgt);
    
    ri=trgt.UserData;
    
    switch(app.data(ri).type)
        case 'logical'
            if app.data((ri)).arraySize > 1
                v=uint32(hex2dec(trgt.String));
                trgt.TooltipString=num2str(v);
            else
                cc=get(trgt,'children');
                v=uint32(find([cc.Value]==1,1)-1);
            end
        case 'single'
            v=typecast(single(str2double(trgt.String)),'uint32');
            trgt.TooltipString=num2str(v);
        otherwise
            v=uint32(hex2dec(trgt.String));
            trgt.TooltipString=num2str(v);
    end
    
    app.data(ri).value=v;
    guidata(app.figH,app);
    try
        app.hw.writeAddr(uint32(app.data(ri).address),v,true);
        if(app.shadowUpdateSelect.Value==1)
            app.hw.shadowUpdate();
        end
        if(app.maresetrestart.Value==1)
            app.hw.runPresetScript('maReset');
            %             pause(1);
            app.hw.runPresetScript('maRestart');
        end
    catch
        fprintf('could not set register!\n');
    end
    valueRead_callback(trgt);
    
end

function valueRead_callback(trgt)
    ri=trgt.UserData;
    app=guidata(trgt);
    v=app.hw.readAddr(uint32(app.data(ri).address));
    app.data(ri).value=v;
    app.data(ri).updated=true;
    guidata(app.figH,app);
    editFIeldUpdate(app,trgt);
    
end

function readBatchButton_callback(varargin)
    app=guidata(varargin{1});
    c=[findobj(app.innerPanel,'style','edit');findobj(app.innerPanel,'type','uibuttongroup')];
    for i=1:length(c)
        valueRead_callback(c(i));
    end
end

function winScroll_callback(e,hslider)
    v=hslider.Value-hslider.SliderStep(1)*e.VerticalScrollCount;
    v=max(0,min(1,v));
    hslider.Value=v;
end

function slider_callback(v)
    app=guidata(v);
    
    val = app.hslider.Value;
    pos = app.innerPanel.Position;
    
    lwst=app.regpanel.Position(4)-pos(4);
    pos(2)=val*lwst;
    app.innerPanel.Position = pos;
end

function regNameEdit_callback(varargin)
    app=guidata(varargin{1});
    %      set_watches(app.figH,false);
    H=17;
    M=5;
    regtoken=app.regNameEdit.String;
    r=regexpi({app.data.regName},regtoken);
    r=cellfun(@(x) ~isempty(x),r);
    r = find(r);
    
    delete(app.innerPanel);
    app.innerPanel = uipanel('Parent',app.regpanel);
    
    app.innerPanel.Units='pixels';
    w=app.innerPanel.Position(3);
    h=length(r)*(M+H)+2*M;
    app.innerPanel.Position = [0 app.regpanel.Position(4)-h w h];
    app.innerPanel.BorderType='none';
    sliderstep = app.regpanel.Position(4)/max(0,(h-app.regpanel.Position(4)));  %  visible length /(total length - visible length)
    
    app.hslider.SliderStep=[min(1/length(r),1),sliderstep];
    
    
    
    btndata = 1-double(repmat(str2img('<'),1,1,3));
    btndata(btndata==1)=nan;
    
    for i=1:length(r)
        a = uicontrol('style','text','parent',app.innerPanel);
        a.HorizontalAlignment = 'left';
        a.Position = [3 h-i*(H+5) 150 H];
        a.String = app.data(r(i)).regName;
        a.UserData=r(i);
        a.TooltipString=['0x' dec2hex(app.data(r(i)).address)];
    end
    b=cell(length(r),1);
    for i=1:length(r)
        
        
        valueBxSz= [160 h-i*(H+M) w-170-H H];
        switch(app.data(r(i)).type)
            case 'logical'
                if app.data(r(i)).arraySize > 1
                    b{i}=uicontrol('style','edit','parent',app.innerPanel,'position',valueBxSz);
                    b{i}.Callback=@(s,e) valueWrite_callback(b{i});
                else
                    b{i} = uibuttongroup('parent',app.innerPanel,'units','pixels','position',valueBxSz);
                    ra(1)=uicontrol('style','radiobutton','units','normalized','parent',b{i},'position',[0 0 .5 1],'string','on');
                    ra(2)=uicontrol('style','radiobutton','units','normalized','parent',b{i},'position',[0.5 0 .5 1],'string','off');
                    b{i}.SelectedObject=[];
                    b{i}.SelectionChangedFcn=@(s,e) valueWrite_callback(b{i});
                end
                
            otherwise
                b{i}=uicontrol('style','edit','parent',app.innerPanel,'position',valueBxSz);
                b{i}.Callback=@(s,e) valueWrite_callback(b{i});
                
                
                
        end
        b{i}.UserData=r(i);
        editFIeldUpdate(app,b{i});
    end
    for i=1:length(r)
        
        readBtn = uicontrol('style','pushbutton','parent',app.innerPanel);
        readBtn.Callback = @(s,e) valueRead_callback(b{i});
        readBtn.Position = [w-H-5 h-i*(H+5) H H];
        readBtn.CData=btndata;
        
    end
    
    if(isempty(app.history.String)|| ~isequal(app.history.String{1},regtoken))
        if(ischar(app.history.String))
            app.history.String={regtoken;app.history.String};
        else
            app.history.String=[regtoken;app.history.String];
        end
        app.history.String=app.history.String(1:min(length(app.history.String),5));
    end
    guidata(app.figH,app);
    drawnow;
    %      set_watches(app.figH,true);
    uicontrol(app.regNameEdit);
    
    
    
    s.regexpHistory=cell2str(app.history.String,',');
    if(isempty(s.regexpHistory))
        s.regexpHistory=' ';
    end
    struct2xmlWrapper(s,app.loadFileName);
    
end

function historySelect_callback(varargin)
    app=guidata(varargin{1});
    app.regNameEdit.String=app.history.String{app.history.Value};
    regNameEdit_callback(varargin{1});
end

function app=createComponents()
    sz=[300 600];
    app.loadFileName='registerUpdateGUI.xml';
    % Create figH
    app.figH = figure('units','pixels',...
        'menubar','none',...
        'name','Verify Password.',...
        'resize','off',...
        'numbertitle','off',...
        'name','IV2 Calibration Tool');
    
    app.figH.Position(3)=sz(1);
    app.figH.Position(4) = sz(2);
    
    centerfig(app.figH );
    
    % Create updateButton
    app.updateButton = uicontrol('style','pushbutton','parent',app.figH);
    app.updateButton.Callback = @readBatchButton_callback;
    app.updateButton.Position = [sz(1)-25 sz(2)-25 20 20];
    btndata = 1-double(repmat(str2img('<'),1,1,3));
    btndata(btndata==1)=nan;
    app.updateButton.CData=btndata;
    
    
    %
    %     % Create regNameEdit
    app.regNameEdit = uicontrol('style','edit','parent',app.figH);
    app.regNameEdit.HorizontalAlignment = 'left';
    app.regNameEdit.Position = [5 sz(2)-25 sz(1)-35 20];
    
    app.regNameEdit.Callback=@regNameEdit_callback;
    app.regNameEdit.String = '';
    
    app.shadowUpdateSelect = uicontrol('style','checkbox','parent',app.figH);
    app.shadowUpdateSelect.String = 'Shadow update';
    app.shadowUpdateSelect.Position = [5 sz(2)-45 110 20];
    app.shadowUpdateSelect.Value = true;
    
    app.maresetrestart = uicontrol('style','checkbox','parent',app.figH);
    app.maresetrestart.String = 'MA reset';
    app.maresetrestart.Position = [125 sz(2)-45 sz(1)-35 20];
    app.maresetrestart.Value = true;
    
    
    app.regpanel = uipanel('Parent',app.figH);
    app.regpanel .Units='pixels';
    app.regpanel.Position = [5 75 sz(1)-27 sz(2)-120];
    
    app.innerPanel=[];
    
    app.hslider = uicontrol('Style','Slider','Parent',app.figH,'Units','Pixels','Position',[sz(1)-20 75 20 app.regpanel.Position(4)],'Value',1);
    app.hslider.Callback=@(s,e)slider_callback(app.figH);
    addlistener(app.hslider,'Value','PostSet',@(s,e)slider_callback(app.figH)); % makes the scrolling movement continuous
    app.figH.WindowScrollWheelFcn=@(s,e) winScroll_callback(e,app.hslider);
    
    
    app.history = uicontrol('Style','listbox','Parent',app.figH,'Units','Pixels','Position',[5 5 sz(1)-10 70]);
    app.history.FontSize=10;
    app.history.Callback=@historySelect_callback;
    if(exist(app.loadFileName,'file'))
        s=xml2structWrapper(app.loadFileName);
        app.history.String=str2cell(s.regexpHistory,',');
    end
    
    
    
    
    
    fw=Firmware;
    app.data=fw.getMeta('^(?!MTLB|EPTG|FRMW.*$).*');
    for i=1:length(app.data)
        app.data(i).value=[];
    end
    app.hw=HWinterface(fw);
    
    
    
    guidata(app.figH,app);
    regNameEdit_callback(app.figH);
    
    
end
