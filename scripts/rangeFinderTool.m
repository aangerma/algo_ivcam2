% mcc -m registerUpdateGUI.m -d \\ger\ec\proj\ha\RSG\SA_3DCam\ohad\ -a ..\+Pipe\tables\* -a ..\@HWinterface\IVCam20Device\* -a ..\@HWinterface\\presetScripts\*
function rangeFinderTool
    createComponents();
    
end

function app=createComponents()
    sz=[900 900];
    
    % Create figH
    app.figH = figure('units','pixels',...
        'menubar','none',...
        'name','Verify Password.',...
        'resize','off',...
        'numbertitle','off',...
        'name','IV2 Range Finder Tool',...
        'CloseRequestFcn',@closeFormFunc);
    
    app.figH.Position(3)=sz(1);
    app.figH.Position(4) = sz(2);
    
    centerfig(app.figH );
    
    % Create startButton
    app.startButton = uicontrol('style','pushbutton','parent',app.figH);
    app.startButton.Callback = @startButton_callback;
    app.startButton.Position = [0 sz(2)-50 sz(1)/2 50];
    btndata = 1-double(repmat(str2img('Start'),1,1,3));
    btndata(btndata==1)=nan;
    app.startButton.CData=btndata;
    
    % Create stopButton
    app.stopButton = uicontrol('style','pushbutton','parent',app.figH);
    app.stopButton.Callback = @stopButton_callback;
    app.stopButton.Position = [sz(1)/2 sz(2)-50 sz(1)/2 50];
    btndata = 1-double(repmat(str2img('stop'),1,1,3));
    btndata(btndata==1)=nan;
    app.stopButton.CData=btndata;
    set(app.stopButton,'Enable','off');
    
    app.depthHistAx = subplot(3,2,1);
    app.depthValsAx = subplot(3,2,2);
    app.irHistAx = subplot(3,2,3);
    app.irValsAx = subplot(3,2,4);
    app.confHistAx = subplot(3,2,5);
    app.confValsAx = subplot(3,2,6);
    
    app.depthVals = [];
    app.irVals = [];
    app.confVals = [];
    
    app.depthLbl = uicontrol('style','text','parent',app.figH,...
        'String','Depth','Position',[10 750 30 20]);
    app.irLbl = uicontrol('style','text','parent',app.figH,...
        'String','IR','Position',[10 450 30 20]);
    app.confLbl = uicontrol('style','text','parent',app.figH,...
        'String','Conf','Position',[10 150 30 20]);
    
    
    app.timer = timer('BusyMode','drop','ExecutionMode','fixedRate','Period',0.2);
    app.timer.TimerFcn = {@timerFun, app.figH};
    
    app.fw=Firmware;
    app.hw=HWinterface(app.fw);
    initHwForRF(app.hw);

    guidata(app.figH,app);
    
end

function closeFormFunc(figH,callbakData)
    try
    app = guidata(figH);
    stop(app.timer);
    delete(app.timer);
    catch 
    end
    closereq;
end
function startButton_callback(varargin)
    app=guidata(varargin{1});
    start(app.timer);
    
    set(app.startButton,'Enable','off');
    set(app.stopButton,'Enable','on');
end

function stopButton_callback(varargin)
    app=guidata(varargin{1});
    stop(app.timer);
    
    set(app.startButton,'Enable','on');
    set(app.stopButton,'Enable','off');
    
end
function timerFun(obj, event, figH)
    app = guidata(figH);
    
    [z,ir,conf] = getRangeFinderData(app.hw);
    app.depthVals = [app.depthVals ; z(:)];
    app.irVals = [app.irVals ; ir(:)];
    app.confVals = [app.confVals ; conf(:)];
    guidata(figH,app);
    dispGraphs(app);
    
end

function [z,ir,conf] = getRangeFinderData(hw)
    frame = hw.getFrame();
    z = mean(frame.z(:));
    ir = mean(frame.i(:));
    conf = mean(frame.c(:)>0);
end

function dispGraphs(app)
    hist(app.depthHistAx, app.depthVals,100);
    plot(app.depthValsAx, app.depthVals);
    hist(app.irHistAx, app.irVals,100);
    plot(app.irValsAx, app.irVals);
    hist(app.confHistAx, app.confVals,100);
    plot(app.confValsAx, app.confVals);
    drawnow;
end

function initHwForRF(hw)
    hw.cmd('dirtybitbypass');
end
